require 'rails_helper'

RSpec.describe Book, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:title) }
    it { should validate_uniqueness_of(:open_library_id).allow_nil }
    it { should belong_to(:author).class_name('Topic') }
  end

  describe '#ensure_open_library_id' do
    let(:author) { create(:topic, type: 'Person', title: 'Mark Twain') }
    let(:book) { create(:book, title: 'The Adventures of Tom Sawyer', author: author) }

    context 'when OpenLibrary lookup succeeds' do
      let(:open_library_response) do
        {
          title: 'The Adventures of Tom Sawyer',
          author_names: ['Mark Twain'],
          open_library_id: 'OL123456W',
          isbn: '0123456789',
          raw_data: { some: 'data' }
        }
      end

      before do
        allow(OpenLibraryService).to receive(:lookup_book)
          .with('The Adventures of Tom Sawyer', 'Mark Twain')
          .and_return(open_library_response)
      end

      it 'updates the open_library_id' do
        expect { book }.to change { Book.where.not(open_library_id: nil).count }.by(1)
        expect(book.reload.open_library_id).to eq('OL123456W')
      end
    end

    context 'when OpenLibrary lookup fails' do
      before do
        allow(OpenLibraryService).to receive(:lookup_book)
          .with('The Adventures of Tom Sawyer', 'Mark Twain')
          .and_return(nil)
      end

      it 'does not update the open_library_id' do
        expect { book }.not_to change { Book.where.not(open_library_id: nil).count }
        expect(book.reload.open_library_id).to be_nil
      end
    end

    context 'when open_library_id is already present' do
      let(:book) { create(:book, title: 'The Adventures of Tom Sawyer', author: author, open_library_id: 'existing_id') }

      it 'does not call OpenLibrary service' do
        expect(OpenLibraryService).not_to receive(:lookup_book)
        book
      end
    end
  end
end 