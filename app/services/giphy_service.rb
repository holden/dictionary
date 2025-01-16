class GiphyService
  include HTTParty
  base_uri 'https://api.giphy.com/v1/gifs'
  include ApiCacheable

  def self.search(term)
    Rails.cache.fetch("giphy/#{term}", expires_in: 1.hour) do
      response = get('/search', {
        query: {
          api_key: Rails.application.credentials.giphy_api_key,
          q: term,
          limit: 25,
          rating: 'g'
        }
      })
      
      return [] unless response.success?

      response['data'].map do |gif|
        {
          title: gif['title'],
          type: 'Gif',
          source_id: gif['id'],
          metadata: {
            poster_url: gif.dig('images', 'fixed_height', 'url'),
            giphy: {
              url: gif['url'],
              embed_url: gif['embed_url'],
              images: gif['images']
            }
          }
        }
      end
    end
  end

  # For the Topic show page - returns simpler format
  def self.search_preview(term, limit = 5)
    Rails.cache.fetch("giphy_preview/#{term}", expires_in: 1.hour) do
      response = get('/search', {
        query: {
          api_key: Rails.application.credentials.giphy_api_key,
          q: term,
          limit: limit,
          rating: 'g'
        }
      })
      
      return [] unless response.success?

      response['data'].map do |gif|
        {
          url: gif.dig('images', 'fixed_height', 'url'),
          width: gif.dig('images', 'fixed_height', 'width'),
          height: gif.dig('images', 'fixed_height', 'height'),
          giphy_url: gif['url']
        }
      end
    end
  end
end 