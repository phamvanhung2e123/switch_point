# frozen_string_literal: true

RSpec.describe SwitchConnection do
  describe '.master_all!' do
    it 'changes connection globally' do
      expect(Book).to connect_to('main_master.sqlite3')
      expect(Book3).to connect_to('main2_master.sqlite3')
      expect(Comment).to connect_to('comment_master.sqlite3')
      expect(User).to connect_to('user.sqlite3')
      expect(BigData).to connect_to('main_master.sqlite3')
      SwitchConnection.master_all!
      expect(Book).to connect_to('main_master.sqlite3')
      expect(Book3).to connect_to('main2_master.sqlite3')
      expect(Comment).to connect_to('comment_master.sqlite3')
      expect(User).to connect_to('user.sqlite3')
      expect(BigData).to connect_to('main_master.sqlite3')
    end

    it 'affects thread-globally' do
      SwitchConnection.master_all!
      Thread.start do
        expect(Book).to connect_to('main_master.sqlite3')
        expect(Book3).to connect_to('main2_master.sqlite3')
        expect(Comment).to connect_to('comment_master.sqlite3')
        expect(User).to connect_to('user.sqlite3')
        expect(BigData).to connect_to('main_master.sqlite3')
      end.join
    end

    context 'within with block' do
      it 'changes the current mode' do
        SwitchConnection.master_all!
        Book.with_slave do
          expect(Book).to connect_to('main_slave.sqlite3')
        end
        expect(Book).to connect_to('main_master.sqlite3')
        Book.with_master do
          expect(Book).to connect_to('main_master.sqlite3')
        end
      end
    end
  end

  describe '.master!' do
    it 'changes connection globally' do
      expect(Book).to connect_to('main_master.sqlite3')
      expect(Publisher).to connect_to('main_master.sqlite3')
      expect(Book).to connect_to('main_master.sqlite3')
      expect(Publisher).to connect_to('main_master.sqlite3')
    end

    it 'affects thread-globally' do
      SwitchConnection.master!(:main)
      Thread.start do
        expect(Book).to connect_to('main_master.sqlite3')
      end.join
    end

    context 'within with block' do
      it 'changes the current mode' do
        Book.with_master do
          SwitchConnection.slave!(:main)
          expect(Book).to connect_to('main_slave.sqlite3')
        end
        expect(Book).to connect_to('main_master.sqlite3')
        Book.with_master do
          expect(Book).to connect_to('main_master.sqlite3')
        end
      end
    end

    context 'with unknown name' do
      it 'raises error' do
        expect { SwitchConnection.master!(:unknown) }.to raise_error(KeyError)
      end
    end
  end

  describe '.with_master' do
    it 'changes connection' do
      SwitchConnection.with_master(:main, :nanika1) do
        expect(Book).to connect_to('main_master.sqlite3')
        expect(Publisher).to connect_to('main_master.sqlite3')
        expect(Nanika1).to connect_to('main_master.sqlite3')
      end
      expect(Book).to connect_to('main_master.sqlite3')
      expect(Publisher).to connect_to('main_master.sqlite3')
      expect(Nanika1).to connect_to('main_master.sqlite3')
    end

    context 'with unknown name' do
      it 'raises error' do
        expect { SwitchConnection.with_master(:unknown) { raise RuntimeError } }.to raise_error(KeyError)
      end
    end
  end

  describe '.with_master_all' do
    it 'changes all connections' do
      expect(Book).to connect_to('main_master.sqlite3')
      expect(Comment).to connect_to('comment_master.sqlite3')
      SwitchConnection.with_master_all do
        expect(Book).to connect_to('main_master.sqlite3')
        expect(Comment).to connect_to('comment_master.sqlite3')
      end
    end
  end
end
