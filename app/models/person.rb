class Person < ApplicationRecord
  include PgSearch::Model
  extend FriendlyId
  
  friendly_id :title, use: :slugged
  
  # Associations
  has_many :quotes, foreign_key: :author_id, dependent: :nullify
  has_many :books, foreign_key: :author_id, dependent: :nullify
  has_and_belongs_to_many :topics

  # Validations  
  validates :title, presence: true, uniqueness: true
  validates :tmdb_id, uniqueness: true, allow_nil: true
  validates :imdb_id, uniqueness: true, allow_nil: true

  # Search configuration
  pg_search_scope :search_by_title,
                 against: :title,
                 using: {
                   tsearch: { prefix: true },
                   trigram: { threshold: 0.3 }
                 }

  # Callbacks
  after_create :ensure_open_library_data, unless: -> { metadata['tmdb'].present? }

  # Display methods
  def display_title
    metadata.dig('open_library', 'name') || title.titleize
  end

  def route_key
    'person'
  end

  def birth_year
    birth_date&.year
  end

  def death_year
    death_date&.year
  end

  def lifespan
    return nil unless birth_year && death_year
    "#{birth_year}-#{death_year}"
  end

  def display_name
    name
  end

  private

  def ensure_open_library_data
    return if open_library_id.present?
    
    if author_data = OpenLibraryService.search_author(title)
      update(
        open_library_id: author_data[:open_library_id],
        birth_date: author_data[:birth_date],
        death_date: author_data[:death_date],
        metadata: metadata.merge(
          open_library: author_data[:raw_data]
        )
      )
    end
  rescue => e
    Rails.logger.error "Error fetching OpenLibrary data for person #{title}: #{e.message}"
  end
end 