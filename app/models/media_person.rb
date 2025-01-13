class MediaPerson < ApplicationRecord
  belongs_to :media
  belongs_to :person

  validates :media_id, uniqueness: { scope: :person_id }
  validates :role, presence: true

  # Common roles could be defined as constants
  ROLES = {
    movie: ['Actor', 'Director', 'Producer', 'Writer'],
    tv_show: ['Actor', 'Director', 'Producer', 'Creator'],
    art: ['Artist', 'Curator']
  }.freeze
end 