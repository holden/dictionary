require 'rails_helper'

RSpec.describe DatamuseService do
  describe '.related_words' do
    it 'fetches related words from Datamuse API' do
      VCR.use_cassette('datamuse/money_related') do
        results = described_class.related_words('money')
        expect(results).to be_an(Array)
        expect(results.first).to include('word', 'score')
      end
    end
  end
end 