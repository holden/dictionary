class Person < ApplicationRecord
  include PgSearch::Model
  extend FriendlyId
  
  friendly_id :title, use: :slugged
  
  # Associations
  has_many :quotes, foreign_key: :author_id, dependent: :nullify
  has_many :books, foreign_key: :author_id, dependent: :nullify
  has_and_belongs_to_many :topics
  has_many :media_people, dependent: :destroy
  has_many :media, through: :media_people

  # Scopes for different media types
  has_many :movies, -> { where(type: 'Movie') }, through: :media_people, source: :media
  has_many :tv_shows, -> { where(type: 'TVShow') }, through: :media_people, source: :media
  has_many :artworks, -> { where(type: 'Art') }, through: :media_people, source: :media

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
  after_create :fetch_open_library_data

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

  def fetch_open_library_data
    return if open_library_id.present?

    if result = OpenLibraryService.search_author(title)
      self.open_library_id = result['key']
      self.metadata = {
        'open_library' => {
          'birth_date' => result['birth_date'],
          'death_date' => result['death_date']
        }
      }
      save!
    end
  end
end 