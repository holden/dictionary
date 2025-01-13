class Art < Media
  validates :artsy_id, uniqueness: true, allow_nil: true

  def self.model_name
    Media.model_name
  end

  # Example of metadata structure:
  # {
  #   creation_date: "1889",
  #   medium: "Oil on canvas",
  #   artsy: {
  #     category: "Painting",
  #     collecting_institution: "MoMA"
  #   }
  # }
end 