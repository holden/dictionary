class Quote < Expression
  has_rich_text :content
  
  before_create :resolve_author
  before_save :clear_attribution_if_author_present

  attribute :attribution_text, :string
  attribute :disputed, :boolean, default: false
  attribute :misattributed, :boolean, default: false
  attribute :original_language, :string
  attribute :original_text, :string
  attribute :source_url, :string
  attribute :citation, :string

  validates :content, presence: true
  validate :author_or_attribution_present
  validates :source_url, uniqueness: { scope: :type, allow_nil: true }

  def self.model_name
    Expression.model_name
  end

  private

  def resolve_author
    return if author_id.present? || attribution_text.blank?

    Rails.logger.info "Resolving author for: #{attribution_text}"

    # Try finding in our database first
    self.author = Person.find_by("lower(title) = ?", attribution_text.downcase)
    if author.present?
      Rails.logger.info "Found existing author: #{author.title}"
      self.attribution_text = nil
      return
    end

    Rails.logger.info "Author not found in database, trying OpenLibrary..."

    # Try creating from OpenLibrary if not found
    if author_data = OpenLibraryService.search_author(attribution_text)
      person = Person.create!(
        title: attribution_text.downcase,
        slug: attribution_text.parameterize,
        open_library_id: author_data[:open_library_id],
        birth_date: author_data[:birth_date],
        death_date: author_data[:death_date],
        metadata: {
          open_library: author_data[:raw_data]
        }
      )
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