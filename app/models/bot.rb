class Bot < ApplicationRecord
  # Voting capabilities
  has_many :votes, as: :voter, dependent: :destroy
  
  # Influences
  has_many :bot_influences, dependent: :destroy
  has_many :influencers, through: :bot_influences, source: :person

  # Validations
  validates :name, presence: true
  validates :personality, presence: true
  validates :base_model, presence: true
  validates :voter_weight, presence: true, numericality: { greater_than: 0 }
  validates :curation_focus, presence: true
end