class Movie < Media
  validates :tmdb_id, uniqueness: true, allow_nil: true
  before_validation :set_type

  def self.model_name
    Media.model_name
  end

  def poster_url
    metadata['poster_path'] && "https://image.tmdb.org/t/p/w500#{metadata['poster_path']}"
  end

  def display_name
    title
  end

  def external_url
    "https://www.themoviedb.org/movie/#{tmdb_id}"
  end

  private

  def set_type
    self.type = 'Movie'
  end
end 