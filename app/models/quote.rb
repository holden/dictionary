class Quote < ApplicationRecord
  belongs_to :topic
  belongs_to :author, class_name: 'Topic', optional: true

  has_rich_text :content

  validates :content, presence: true
  validates :topic, presence: true
  
  # Ensure either author_id or attribution_text is present
  validates :attribution_text, presence: true, if: -> { author_id.blank? }
  validates :author_id, presence: true, if: -> { attribution_text.blank? }
  validate :author_or_attribution_present

  private

  def author_or_attribution_present
    if author_id.blank? && attribution_text.blank?
      errors.add(:base, "Must have either an author or attribution text")
    end
  end
end 