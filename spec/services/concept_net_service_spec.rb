require 'rails_helper'

RSpec.describe ConceptNetService do
  describe '#lookup' do
    let(:service) { described_class.new }
    
    context 'with a valid term' do
      let(:term) { 'elephant' }
      let(:api_response) do
        {
          '@id' => '/c/en/elephant',
          'edges' => [],
          'view' => {
            'comment' => 'A large mammal...'
          }
        }
      end

      before do
        stub_request(:get, "http://api.conceptnet.io/c/en/elephant")
          .to_return(
            status: 200,
            body: api_response.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns the parsed response' do
        result = service.lookup(term)
        expect(result).to include('@id' => '/c/en/elephant')
      end
    end

    context 'with special characters' do
      let(:term) { 'ice cream' }
      
      before do
        stub_request(:get, "http://api.conceptnet.io/c/en/ice_cream")
          .to_return(
            status: 200,
            body: { '@id' => '/c/en/ice_cream' }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'handles spaces and special characters' do
        result = service.lookup(term)
        expect(result).to include('@id' => '/c/en/ice_cream')
      end
    end

    context 'when the API redirects' do
      let(:term) { 'elephant' }
      let(:redirect_url) { 'http://api.conceptnet.io/c/en/elephant/' }
      let(:api_response) do
        {
          '@id' => '/c/en/elephant',
          'edges' => [],
          'view' => {
            'comment' => 'A large mammal...'
          }
        }
      end

      before do
        stub_request(:get, "http://api.conceptnet.io/c/en/elephant")
          .to_return(
            status: 301,
            headers: { 'Location' => redirect_url }
          )

        stub_request(:get, redirect_url)
          .to_return(
            status: 200,
            body: api_response.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'follows the redirect and returns the parsed response' do
        result = service.lookup(term)
        expect(result).to include('@id' => '/c/en/elephant')
      end
    end
  end
end 