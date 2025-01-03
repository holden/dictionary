class Quote < ApplicationRecord
  belongs_to :topic
  belongs_to :author, class_name: 'Person', optional: true
  belongs_to :user

  has_rich_text :content

  validates :content, presence: true
  validates :user, presence: true
end 