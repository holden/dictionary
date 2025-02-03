class Expression < ApplicationRecord
  belongs_to :author, class_name: 'Person'
  belongs_to :topic, optional: true
  belongs_to :user, optional: true

  has_many :expression_topics, dependent: :destroy
  has_many :topics, through: :expression_topics

  validates :content, presence: true
  validates :author, presence: true
  validates :year_written, numericality: { 
    only_integer: true,
    greater_than: 0,
    less_than_or_equal_to: Time.current.year
  }, allow_nil: true

  # Scopes
  scope :recent_first, -> { order(created_at: :desc) }
  scope :by_author, ->(author_id) { where(author_id: author_id) }
  scope :by_topic, ->(topic_id) { where(topic_id: topic_id) }
  
  def display_text
    "#{content} - #{author.title}"
  end
end 