class Quote < ApplicationRecord
  belongs_to :topic

  validates :content, presence: true
  validates :topic, presence: true
end 