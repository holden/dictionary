class Movie < Media
  validates :tmdb_id, uniqueness: true, allow_nil: true
  before_validation :set_type

  def self.model_name
    Media.model_name
  end

  def poster_url
    return nil if metadata.blank? || !metadata['poster_path'].present?
    return metadata['poster_path'] if metadata['poster_path'].start_with?('http')
    "https://image.tmdb.org/t/p/w500#{metadata['poster_path']}"
  end

  def display_poster
    poster_url.presence || 'https://placehold.co/400x600/png?text=No+Poster'
  end

  private

  def set_type
    self.type = 'Movie'
  end
end 