class Photo < Media
  validates :unsplash_id, uniqueness: true, allow_nil: true
  before_validation :set_type

  def self.model_name
    Media.model_name
  end

  # Metadata accessors
  def thumb_url
    metadata.dig('urls', 'thumb')
  end

  def full_url
    metadata.dig('urls', 'full')
  end

  def photographer_name
    metadata.dig('user', 'name')
  end

  def photographer_username
    metadata.dig('user', 'username')
  end

  def photographer_url
    "https://unsplash.com/@#{photographer_username}?utm_source=devils_dictionary&utm_medium=referral"
  end

  # Example of metadata structure:
  # {
  #   description: "A beautiful landscape",
  #   alt_description: "Mountain vista at sunset",
  #   width: 4000,
  #   height: 3000,
  #   color: "#60544D",
  #   blur_hash: "LPF#XMx]...",
  #   urls: {
  #     raw: "https://...",
  #     full: "https://...",
  #     regular: "https://...",
  #     small: "https://...",
  #     thumb: "https://..."
  #   },
  #   user: {
  #     name: "John Smith",
  #     username: "johnsmith",
  #     portfolio_url: "https://..."
  #   }
  # }

  private

  def set_type
    self.type = 'Photo'
  end
end 