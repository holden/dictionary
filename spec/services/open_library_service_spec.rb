require 'rails_helper'

RSpec.describe OpenLibraryService do
  describe '.lookup_author' do
    it 'fetches author data from OpenLibrary API' do
      VCR.use_cassette('openlibrary/ambrose_bierce') do
        result = described_class.lookup_author('ambrose bierce')
        expect(result).to include('key', 'name')
        expect(result['name']).to include('Bierce')
      end
    end
  end
end 