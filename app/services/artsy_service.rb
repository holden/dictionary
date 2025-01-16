class ArtsyService
  include HTTParty
  base_uri 'https://api.artsy.net/api'
  include ApiCacheable

  def initialize
    @token = fetch_token
  end

  def search(query)
    return [] unless @token

    Rails.logger.info "Searching Artsy for: #{query}"
    Rails.logger.info "Using token: #{@token}"

    response = self.class.get('/search', {
      query: { 
        q: query,
        type: 'artwork'
      },
      headers: {
        'X-Xapp-Token' => @token,
        'Accept' => 'application/vnd.artsy-v2+json'
      }
    })

    Rails.logger.info "Artsy API Response status: #{response.code}"
    Rails.logger.info "Artsy API Response body: #{response.body}"

    return [] unless response.success?
    parse_artworks(response.parsed_response)
  end

  def self.search_artworks(query)
    cache_api_response("artsy/#{query.downcase}") do
      # API call implementation
    end
  end

  private

  def fetch_token
    response = self.class.post('/tokens/xapp_token', {
      body: {
        client_id: Rails.application.credentials.artsy.client_id,
        client_secret: Rails.application.credentials.artsy.client_secret
      }
    })

    Rails.logger.info "Token fetch response status: #{response.code}"
    
    return nil unless response.success?
    response.parsed_response['token']
  end

  def parse_artworks(data)
    return [] unless data.dig('_embedded', 'results')

    data['_embedded']['results'].map do |result|
      {
        title: result['title'],
        image_url: result.dig('_links', 'thumbnail', 'href'),
        artist: result.dig('_embedded', 'artists', 0, 'name'),
        artwork_url: result.dig('_links', 'self', 'href')&.gsub('api.artsy.net/api/artworks', 'www.artsy.net/artwork'),
        date: result['date']
      }
    end
  rescue => e
    Rails.logger.error "Error parsing Artsy response: #{e.message}"
    []
  end
end 