class Media < ApplicationRecord
  # Specify table name since we're not using standard Rails pluralization
  self.table_name = 'media'
  
  # Configure STI
  self.inheritance_column = 'type'
  
  # Map database types to class names
  def self.sti_name
    case name
    when 'TvShow'
      'TVShow'
    else
      name
    end
  end

  def self.find_sti_class(type_name)
    case type_name
    when 'TVShow'
      TvShow
    else
      super
    end
  end
  
  has_many :media_people, dependent: :destroy
  has_many :people, through: :media_people
  has_and_belongs_to_many :topics

  validates :title, presence: true
  validates :type, presence: true

  # Scopes
  scope :movies, -> { where(type: 'Movie') }
  scope :tv_shows, -> { where(type: 'TVShow') }
  scope :photos, -> { where(type: 'Photo') }
end 