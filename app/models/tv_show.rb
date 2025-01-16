class TvShow < Media
  validates :source_id, uniqueness: { scope: :source_type }, allow_nil: true
  before_validation :set_source_type

  def self.model_name
    Media.model_name
  end

  def poster_url
    metadata['poster_path']
  end

  def display_name
    title
  end

  def external_url
    "https://www.themoviedb.org/tv/#{source_id}"
  end

  private

  def set_source_type
    self.source_type = 'TMDB'
  end
end 