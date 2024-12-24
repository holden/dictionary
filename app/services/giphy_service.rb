class GiphyService
  include HTTParty
  base_uri 'https://api.giphy.com/v1/gifs'

  def self.search(term)
    Rails.cache.fetch("giphy/#{term}", expires_in: 1.hour) do
      response = get('/search', {
        query: {
          api_key: Rails.application.credentials.giphy_api_key,
          q: term,
          limit: 5,
          rating: 'g'
        }
      })

      return [] unless response.success?

      response['data'].map do |gif|
        {
          url: gif.dig('images', 'fixed_height', 'url'),
          width: gif.dig('images', 'fixed_height', 'width'),
          height: gif.dig('images', 'fixed_height', 'height'),
          giphy_url: gif['url']  # Add the Giphy URL
        }
      end
    end
  end
end 