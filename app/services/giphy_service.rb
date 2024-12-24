class GiphyService
  include HTTParty
  base_uri 'api.giphy.com/v1/gifs'

  def self.search(term, limit: 5)
    response = get('/search', query: {
      q: term,
      api_key: Rails.application.credentials.giphy_api_key,
      limit: limit,
      rating: 'g'  # Keep it family-friendly
    })

    return nil unless response.success?

    response.parsed_response['data'].map do |gif|
      {
        url: gif.dig('images', 'fixed_width', 'url'),
        width: gif.dig('images', 'fixed_width', 'width'),
        height: gif.dig('images', 'fixed_width', 'height')
      }
    end
  end
end 