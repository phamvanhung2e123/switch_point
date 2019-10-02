# frozen_string_literal: true

require 'pry'
require 'logger'

RSpec.describe SwitchConnection::Relation::MonkeyPatch do
  before do
    Book.with_master do
      Book.create
    end
  end

  let(:first_id_in_master_db) { Book.with_master { Book.all.first.id } }
  describe '.pluck' do
    subject { Book.pluck(:id) }
    context 'when connect to master' do
      it 'id is found' do
        Book.with_master { is_expected.to eq([first_id_in_master_db]) }
        expect(Book.with_master { Book.pluck(:id) }).to eq [first_id_in_master_db]
      end
    end

    context 'when connect to slave' do
      it 'id is not found' do
        is_expected.to eq([])
      end
    end

    context 'when thread safe' do
      it 'work with thread save' do
        Thread.start do
          Book.with_master { expect(Book.pluck(:id)).to eq([first_id_in_master_db]) }
          expect(Book.with_master { Book.pluck(:id) }).to eq [first_id_in_master_db]
          expect(Book.pluck(:id)).to eq([])
        end.join
      end
    end
  end

  describe '.exists?' do
    subject { Book.where(id: first_id_in_master_db).exists? }

    context 'when connect to master' do
      it 'id is exist' do
        Book.with_master { is_expected.to eq true }
        expect(Book.with_master { Book.where(id: first_id_in_master_db).exists? }).to eq true
      end
    end

    context 'when connect to slave' do
      it 'id is not exist' do
        is_expected.to eq false
      end
    end

    context 'when in multi thread' do
      it 'thread safe' do
        Thread.start do
          Book.with_master { expect(Book.where(id: first_id_in_master_db).exists?).to eq true }
          expect(Book.with_master { Book.where(id: first_id_in_master_db).exists? }).to eq true
          expect(Book.where(id: first_id_in_master_db).exists?).to eq false
        end.join
      end
    end
  end

  describe '.exists?' do
    subject { Book.where(id: first_id_in_master_db).count }

    context 'when connect to master' do
      it 'id is exist' do
        Book.with_master { is_expected.to eq 1 }
        expect(Book.with_master { Book.where(id: first_id_in_master_db).count }).to eq 1
      end
    end

    context 'when connect to slave' do
      it 'id is not exist' do
        is_expected.to eq 0
      end
    end

    context 'when in multi thread' do
      it 'thread safe' do
        Thread.start do
          Book.with_master { expect(Book.where(id: first_id_in_master_db).count).to eq 1 }
          expect(Book.with_master { Book.where(id: first_id_in_master_db).count }).to eq 1
          expect(Book.where(id: first_id_in_master_db).count).to eq 0
        end.join
      end
    end
  end
end
