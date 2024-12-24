class ArtsyService
  include HTTParty
  base_uri 'https://api.artsy.net/api'

  def initialize
    @token = fetch_token
  end

  def search(term, limit: 5)
    return [] unless @token

    response = self.class.get('/search', {
      query: { 
        q: term,
        size: limit,
        type: 'artwork'
      },
      headers: {
        'X-Xapp-Token' => @token,
        'Accept' => 'application/vnd.artsy-v2+json'
      }
    })

    return [] unless response.success?
    parse_artworks(response.parsed_response)
  end

  private

  def fetch_token
    response = self.class.post('/tokens/xapp_token', {
      body: {
        client_id: Rails.application.credentials.dig(:artsy, :client_id),
        client_secret: Rails.application.credentials.dig(:artsy, :client_secret)
      }
    })

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