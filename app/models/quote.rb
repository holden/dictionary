class Quote < ApplicationRecord
  belongs_to :topic
  belongs_to :author, class_name: 'Topic', optional: true

  has_rich_text :content

  validates :content, presence: true
  validates :topic, presence: true
end 