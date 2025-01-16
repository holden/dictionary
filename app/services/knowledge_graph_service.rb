class KnowledgeGraphService
  include HTTParty
  base_uri 'https://kgsearch.googleapis.com/v1'
  include ApiCacheable

  def self.search(term)
    Rails.cache.fetch("knowledge_graph/#{term}", expires_in: 1.hour) do
      response = get('/entities:search', {
        query: {
          query: term,
          types: 'Person',
          limit: 10,
          key: Rails.application.credentials.google.knowledge_graph_api_key
        }
      })
      
      return [] unless response.success?

      response['itemListElement'].map do |item|
        result = item['result']
        {
          name: result['name'],
          knowledge_graph_id: result['@id']&.gsub('kg:', ''),
          description: result['description'],
          detailed_description: result['detailedDescription']&.dig('articleBody'),
          image_url: result['image']&.dig('contentUrl'),
          score: item['resultScore'],
          url: result['url']
        }
      end
    end
  end
end 