class KnowledgeGraphService
  include HTTParty
  base_uri 'https://kgsearch.googleapis.com/v1'

  def self.search(term)
    response = get('/entities:search', {
      query: {
        query: term,
        types: 'Person',
        limit: 25,  # Get more results initially so we can filter
        key: Rails.application.credentials.google.knowledge_graph_api_key
      }
    })
    
    return [] unless response.success?

    # Process and filter results
    results = response['itemListElement']
      .select { |item| item['resultScore'].to_f > 100 }  # Filter low-scoring results
      .map do |item|
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

    # Remove duplicates by name and sort by score
    results.uniq { |r| r[:name] }
           .sort_by { |r| -r[:score].to_f }
           .take(5)  # Limit to top 5 results
  end
end 