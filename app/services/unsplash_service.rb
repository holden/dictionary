class UnsplashService
  include HTTParty
  base_uri 'https://api.unsplash.com'

  def initialize
    @options = {
      headers: {
        'Authorization' => "Client-ID #{Rails.application.credentials.dig(:unsplash, :access_key)}",
        'Accept-Version' => 'v1'
      }
    }
  end

  def search(query, page: 1, per_page: 10)
    response = self.class.get('/search/photos', @options.merge(
      query: { 
        query: query,
        page: page,
        per_page: per_page
      }
    ))

    return [] unless response.success?

    response['results'].map do |result|
      {
        title: result['description'] || result['alt_description'] || 'Untitled',
        type: 'Photo',
        unsplash_id: result['id'],
        metadata: {
          description: result['description'],
          alt_description: result['alt_description'],
          width: result['width'],
          height: result['height'],
          color: result['color'],
          blur_hash: result['blur_hash'],
          urls: {
            raw: result['urls']['raw'],
            full: result['urls']['full'],
            regular: result['urls']['regular'],
            small: result['urls']['small'],
            thumb: result['urls']['thumb']
          },
          user: {
            name: result['user']['name'],
            username: result['user']['username'],
            portfolio_url: result['user']['portfolio_url']
          }
        }
      }
    end
  rescue StandardError => e
    Rails.logger.error "Unsplash API error: #{e.message}"
    []
  end
end 