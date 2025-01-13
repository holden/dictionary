class Movie < Media
  validates :tmdb_id, uniqueness: true, allow_nil: true

  def self.model_name
    Media.model_name
  end

  # Example of metadata structure:
  # {
  #   release_date: "2024-01-15",
  #   genre: "Action",
  #   runtime: 120,
  #   tmdb: {
  #     vote_average: 8.5,
  #     popularity: 95.4
  #   }
  # }
end 