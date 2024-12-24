class Definition < ApplicationRecord
  belongs_to :topic
  belongs_to :author, polymorphic: true, optional: true
  belongs_to :source, polymorphic: true, optional: true

  has_rich_text :content

  validates :content, presence: true
  validate :must_have_author_or_source
  validate :source_must_be_valid_type

  private

  def must_have_author_or_source
    if author.blank? && source.blank?
      errors.add(:base, "Definition must have either an author or a source")
    end
  end

  def source_must_be_valid_type
    return if source.blank?
    unless source.is_a?(Book) || source.is_a?(Website)
      errors.add(:source, "must be a Book or Website")
    end
  end
end 