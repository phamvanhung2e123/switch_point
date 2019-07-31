# frozen_string_literal: true

RSpec.describe SwitchPoint::Model do
  describe '.use_switch_point' do
    after do
      Book.use_switch_point :main
    end

    it 'changes connection' do
      expect(Book).to connect_to('main_master.sqlite3')
      Book.use_switch_point :comment
      expect(Book).to connect_to('comment_master.sqlite3')

      Thread.start do
        Book.with_switch_point(:main) do
          expect(Book).to connect_to('main_master.sqlite3')
        end
        Book.with_switch_point(:comment) do
          expect(Book).to connect_to('comment_master.sqlite3')
        end
      end.join
    end

    context 'with non-existing switch point name' do
      it 'raises error' do
        expect {
          Class.new(ActiveRecord::Base) do
            use_switch_point :not_found
          end
        }.to raise_error(KeyError)
      end
    end
  end

  describe '.connection' do
    it 'returns master connection by default' do
      expect(Book).to connect_to('main_master.sqlite3')
      expect(Publisher).to connect_to('main_master.sqlite3')
      expect(User).to connect_to('user.sqlite3')
      expect(Comment).to connect_to('comment_master.sqlite3')
      expect(Note).to connect_to('default.sqlite3')
      expect(Book.switch_point_proxy).to be_master
    end

    context 'when auto_master is disabled' do
      it 'raises error when destructive query is requested in slave mode' do
        expect { Book.create }.to_not raise_error
        expect { Book.with_master { Book.create } }.to_not raise_error
      end
    end

    context 'when auto_master is enabled' do
      around do |example|
        SwitchPoint.configure do |config|
          config.auto_master = true
        end
        example.run
        SwitchPoint.configure do |config|
          config.auto_master = false
        end
      end

      it 'executes after_save callback in slave mode!' do
        book = Book.new
        expect(book).to receive(:do_after_save) {
          expect(Book.switch_point_proxy).to be_master
          expect(Book.connection.open_transactions).to eq(1)
        }
        book.save!
      end
    end

    it 'works with newly checked-out connection' do
      Thread.start do
        Book.with_master do
          Book.create
        end
        Book.with_slave { expect(Book.count).to eq(0) }
        Book.with_master { expect(Book.count).to eq(1) }
      end.join
    end

    context 'without switch_point configuration' do
      it 'returns default connection' do
        expect(Note.connection).to equal(ActiveRecord::Base.connection)
      end
    end

    context 'with the same switch point name' do
      it 'shares connection' do
        expect(Book.connection).to equal(Publisher.connection)
      end
    end

    context 'with the same database name' do
      it 'does NOT shares a connection' do
        expect(Book.connection).to_not equal(BigData.connection)
        Book.with_master do
          BigData.with_master do
            expect(Book.connection).to_not equal(BigData.connection)
          end
        end
      end
    end

    context 'when superclass uses use_switch_point' do
      context 'without use_switch_point in derived class' do
        it 'inherits switch_point configuration' do
          expect(DerivedNanika1).to connect_to('main_master.sqlite3')
        end

        it 'shares connection with superclass' do
          expect(DerivedNanika1.connection).to equal(AbstractNanika.connection)
        end
      end

      context 'with use_switch_point in derived class' do
        it 'overrides superclass' do
          expect(DerivedNanika2).to connect_to('main2_master.sqlite3')
        end
      end

      context 'when superclass changes switch_point' do
        after do
          AbstractNanika.use_switch_point :main
        end

        it 'follows' do
          AbstractNanika.use_switch_point :main2
          expect(DerivedNanika1).to connect_to('main2_master.sqlite3')
        end
      end
    end

    context 'without :master' do
      it 'sends destructive queries to ActiveRecord::Base' do
        expect(Nanika1).to connect_to('main_master.sqlite3')
        Nanika1.with_master do
          expect(Nanika1).to connect_to('main_master.sqlite3')
        end
      end
    end

    context 'without :slave' do
      it 'sends all queries to :master' do
        expect(Nanika3).to connect_to('comment_master.sqlite3')
        Nanika3.with_master do
          expect(Nanika3).to connect_to('comment_master.sqlite3')
          Nanika3.create
        end
        expect(Nanika3.count).to eq(1)
        expect(Nanika3.with_slave { Nanika3.connection }).to equal(Nanika3.with_master { Nanika3.connection })
      end
    end
  end

  describe '.with_master' do
    it 'changes connection locally' do
      Book.with_master do
        expect(Book).to connect_to('main_master.sqlite3')
        expect(Book.switch_point_proxy).to be_master
      end
      expect(Book).to connect_to('main_master.sqlite3')
      expect(Book.switch_point_proxy).to be_master
    end

    it 'changes connection locally' do
      Book.with_switch_point(:comment) do
        expect(Book.switch_point_proxy).to be_master
        expect(Book).to connect_to('comment_master.sqlite3')
        Thread.start do
          expect(Book).to connect_to('main_master.sqlite3')
        end.join
      end

      expect(Book.switch_point_proxy).to be_master
      expect(Book).to connect_to('main_master.sqlite3')
    end

    it 'affects to other models with the same switch point' do
      Book.with_master do
        expect(Publisher).to connect_to('main_master.sqlite3')
      end
      expect(Publisher).to connect_to('main_master.sqlite3')
    end

    it 'does not affect to other models with different switch point' do
      Book.with_master do
        expect(Comment).to connect_to('comment_master.sqlite3')
      end
    end

    context 'with the same switch point' do
      it 'shares connection' do
        Book.with_master do
          expect(Book.connection).to equal(Publisher.connection)
        end
      end
    end

    context 'without use_switch_point' do
      it 'raises error' do
        expect { Note.with_master { :bypass } }.to raise_error(SwitchPoint::UnconfiguredError)
      end
    end

    it 'affects thread-locally' do
      Book.with_slave do
        expect(Book).to connect_to('main_slave.sqlite3')
        Thread.start do
          expect(Book).to connect_to('main_master.sqlite3')
        end.join
      end
    end
  end

  describe '#with_master' do
    it 'behaves like .with_master' do
      book = Book.with_master { Book.create! }
      book.with_master do
        expect(Book).to connect_to('main_master.sqlite3')
      end
      expect(Book).to connect_to('main_master.sqlite3')
    end
  end

  describe '.with_slave' do
    context 'when master! is called globally' do
      before do
        SwitchPoint.master!(:main)
      end

      it 'locally overwrites global mode' do
        Book.with_slave do
          expect(Book).to connect_to('main_slave.sqlite3')
        end
        expect(Book).to connect_to('main_master.sqlite3')
      end
    end
  end

  describe '#with_slave' do
    it 'behaves like .with_slave' do
      book = Book.create!
      book.with_slave do
        expect(Book).to connect_to('main_slave.sqlite3')
      end
      expect(Book).to connect_to('main_master.sqlite3')
    end
  end

  describe '#with_mode' do
    it 'raises error if unknown mode is given' do
      expect { SwitchPoint::ProxyRepository.checkout(:main).with_mode(:typo) }.to raise_error(ArgumentError)
    end
  end

  describe '.switch_name' do
    after do
      Book.switch_point_proxy.reset_name!
    end

    it 'switches proxy configuration' do
      Book.switch_point_proxy.switch_name(:comment)
      expect(Book).to connect_to('comment_master.sqlite3')
      expect(Publisher).to connect_to('comment_master.sqlite3')
    end

    context 'with block' do
      it 'switches proxy configuration locally' do
        Book.switch_point_proxy.switch_name(:comment) do
          expect(Book).to connect_to('comment_master.sqlite3')
          expect(Publisher).to connect_to('comment_master.sqlite3')
        end
        expect(Book).to connect_to('main_master.sqlite3')
        expect(Publisher).to connect_to('main_master.sqlite3')
      end
    end
  end

  describe '.transaction_with' do
    context 'when each model has a same master' do
      before do
        @before_book_count  = Book.count
        @before_book2_count = Book2.count

        Book.transaction_with(Book2) do
          Book.create
          Book2.create
        end

        @after_book_count = Book.with_master do
          Book.count
        end
        @after_book2_count = Book2.with_master do
          Book2.count
        end
      end

      it 'should create a new record' do
        expect(
          Book.with_master do
            Book.count
          end
        ).to be > @before_book_count

        expect(
          Book2.with_master do
            Book2.count
          end
        ).to be > @before_book2_count
      end
    end

    context 'when each model has a other master' do
      it {
        expect {
          Book.transaction_with(Book3) do
            Book.create
            Book3.create
          end
        }.to raise_error(SwitchPoint::Error)
      }
    end

    context 'when raise exception in transaction that include some model, and models each have other master' do
      before do
        @before_book_count  = Book.count
        @before_book3_count = Book3.count

        Book.transaction_with(Book2) do
          Book.create
          Book3.with_master do
            Book3.create
          end
          raise ActiveRecord::Rollback
        end
      end

      it 'Book should not create a new record (rollbacked)' do
        expect(
          Book.with_master do
            Book.count
          end
        ).to eq @before_book_count
      end

      it 'Book3 should create a new record (not rollbacked)' do
        expect(
          Book3.with_master do
            Book3.count
          end
        ).to be > @before_book3_count
      end
    end

    context 'when nested transaction_with then parent transaction rollbacked' do
      before do
        @before_book_count  = Book.count
        @before_book3_count = Book3.count

        Book.transaction_with do
          Book.create

          Book3.transaction_with do
            Book3.create
          end

          raise ActiveRecord::Rollback
        end

        it {
          expect(
            Book.with_master do
              Book.count
            end
          ).to be = @before_book_count

          expect(
            Book3.with_master do
              Book3.count
            end
          ).to be > @before_book3_count
        }
      end
    end
  end

  describe '#transaction_with' do
    it 'behaves like .transaction_with' do
      book = Book.with_master { Book.create! }
      expect(Book.with_master { Book.count }).to eq(1)
      book.transaction_with(Book2) do
        Book.create!
        raise ActiveRecord::Rollback
      end
      expect(Book.with_master { Book.count }).to eq(1)

      expect { book.transaction_with(Book3) {} }.to raise_error(SwitchPoint::Error)
    end
  end
end
