require 'rails_helper'

RSpec.describe ConceptNetService do
  describe '.lookup' do
    it 'fetches concept data from ConceptNet API' do
      VCR.use_cassette('conceptnet/money_lookup') do
        result = described_class.lookup('money')
        expect(result).to include('@id')
        expect(result['@id']).to eq('/c/en/money')
      end
    end
  end
end 