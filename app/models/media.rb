class Media < ApplicationRecord
  has_many :media_people, dependent: :destroy
  has_many :people, through: :media_people

  validates :title, presence: true
  validates :type, presence: true

  # Scopes
  scope :movies, -> { where(type: 'Movie') }
  scope :tv_shows, -> { where(type: 'TVShow') }
  scope :artworks, -> { where(type: 'Art') }
end 