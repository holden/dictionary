class Art < Media
  validates :source_id, uniqueness: { scope: :source_type }, allow_nil: true
  before_validation :set_source_type

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

  private

  def set_source_type
    self.source_type = 'Artsy'
  end
end 