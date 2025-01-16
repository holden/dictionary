class Media < ApplicationRecord
  validates :title, presence: true
  validates :type, presence: true
  validates :source_id, uniqueness: { scope: :source_type }, allow_nil: true

  scope :movies, -> { where(type: 'Movie') }
  scope :tv_shows, -> { where(type: 'TVShow') }
  scope :photos, -> { where(type: 'Photo') }
  scope :art, -> { where(type: 'Art') }

  def self.find_by_source(source_type, source_id)
    find_by(source_type: source_type, source_id: source_id)
  end
end 