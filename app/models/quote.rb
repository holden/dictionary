class Quote < ApplicationRecord
  belongs_to :topic
  belongs_to :author, class_name: 'Person', optional: true
  
  has_rich_text :content

  validates :content, presence: true
  validates :topic, presence: true
  
  # Ensure we have either an author or attribution_text
  validate :must_have_attribution_or_author
  
  # Scopes for common queries
  scope :with_author, -> { where.not(author_id: nil) }
  scope :with_attribution, -> { where.not(attribution_text: nil) }
  scope :chronological, -> { order(said_on: :asc) }
  scope :recent_first, -> { order(created_at: :desc) }

  # Helper method to store Wikiquote-specific metadata
  def store_wikiquote_metadata(data)
    self.metadata = self.metadata.merge(wikiquote: data)
    save
  end

  # Helper method to set the author, creating a Person record if needed
  def set_author(name)
    return if name.blank?
    
    # Try to find existing Person topic
    person = Person.find_by('LOWER(title) = ?', name.downcase)
    
    unless person
      # Try to fetch from ConceptNet/OpenLibrary APIs
      person = Person.create_from_apis(name)
      
      # If APIs fail, create a basic person record
      person ||= Person.create(title: name)
    end
    
    update(author: person)
  end

  private

  def must_have_attribution_or_author
    if attribution_text.blank? && author_id.nil?
      errors.add(:base, 'Must have either an attribution text or an author')
    end
  end
end 