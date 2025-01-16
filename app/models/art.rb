class Art < Media
  validates :artsy_id, uniqueness: true, allow_nil: true

  def self.model_name
    Media.model_name
  end

  def poster_url
    metadata['poster_url']
  end

  def display_name
    artist = metadata.dig('artsy', 'artist')
    artist.present? ? "#{title} by #{artist}" : title
  end

  def external_url
    metadata.dig('artsy', 'artwork_url')
  end
end 