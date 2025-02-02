class GeniusService
  include HTTParty
  base_uri 'https://api.genius.com'

  def self.search(query)
    new.search(query)
  end

  def initialize
    @access_token = Rails.application.credentials.genius.access_token
  end

  def search(query)
    response = self.class.get('/search', query: {
      q: query
    }, headers: auth_headers)

    return [] unless response.success?

    parse_search_results(response)
  end

  private

  def auth_headers
    {
      'Authorization' => "Bearer #{@access_token}"
    }
  end

  def parse_search_results(response)
    response['response']['hits'].map do |hit|
      {
        title: hit['result']['title'],
        artist: hit['result']['primary_artist']['name'],
        url: hit['result']['url'],
        lyrics_url: hit['result']['url'],
        source_url: hit['result']['url'],
        source_title: hit['result']['title'],
        year_written: hit['result']['release_date_components']&.fetch('year', nil),
        attribution_text: hit['result']['primary_artist']['name'],
        metadata: {
          genius: hit['result'].slice(
            'id', 'title', 'url', 'path', 
            'header_image_url', 'song_art_image_url'
          ).merge(
            artist_id: hit['result']['primary_artist']['id'],
            artist_url: hit['result']['primary_artist']['url']
          )
        }
      }
    end
  end
end 