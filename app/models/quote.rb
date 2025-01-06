class Quote < ApplicationRecord
  belongs_to :topic
  belongs_to :author, class_name: 'Person', optional: true
  belongs_to :user, optional: true

  before_create :resolve_author
  before_save :clear_attribution_if_author_present

  has_rich_text :content

  validates :content, presence: true
  validates :user, presence: true
  validate :author_or_attribution_present

  private

  def resolve_author
    return if author_id.present? || attribution_text.blank?

    Rails.logger.info "Resolving author for: #{attribution_text}"

    # Try finding in our database first
    self.author = Person.find_by("lower(title) = ? AND type = 'Person'", attribution_text.downcase)
    if author.present?
      Rails.logger.info "Found existing author: #{author.title}"
      self.attribution_text = nil
      return
    end

    Rails.logger.info "Author not found in database, trying OpenLibrary..."

    # Try creating from OpenLibrary if not found
    if (person = Person.find_or_create_from_open_library(attribution_text))
      Rails.logger.info "Created author from OpenLibrary: #{person.title}"
      self.author = person
      self.attribution_text = nil
    else
      Rails.logger.info "Failed to find or create author from OpenLibrary"
    end
  end

  def clear_attribution_if_author_present
    self.attribution_text = nil if author_id.present?
  end

  def author_or_attribution_present
    return if author_id.present? || attribution_text.present?
    errors.add(:base, 'Must have either an author or attribution text')
  end
end 