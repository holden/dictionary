class Media < ApplicationRecord
  # Specify table name since we're not using standard Rails pluralization
  self.table_name = 'media'
  
  has_many :media_people, dependent: :destroy
  has_many :people, through: :media_people
  has_and_belongs_to_many :topics

  validates :title, presence: true
  validates :type, presence: true

  # Scopes
  scope :movies, -> { where(type: 'Movie') }
  scope :tv_shows, -> { where(type: 'TVShow') }
  scope :artworks, -> { where(type: 'Art') }
end 