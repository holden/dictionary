class BotInfluence < ApplicationRecord
  belongs_to :bot
  belongs_to :person

  validates :influence_weight, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :bot_id, uniqueness: { scope: :person_id }
end 