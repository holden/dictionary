class TVShow < Media
  validates :tmdb_id, uniqueness: true, allow_nil: true

  def self.model_name
    Media.model_name
  end

  # Example of metadata structure:
  # {
  #   first_air_date: "2024-01-15",
  #   genre: "Drama",
  #   seasons: 3,
  #   tmdb: {
  #     status: "Running",
  #     episode_count: 36
  #   }
  # }
end 