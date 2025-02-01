class Vote < ApplicationRecord
  # Associations
  belongs_to :votable, polymorphic: true
  belongs_to :voter, polymorphic: true

  # Validations
  validates :vote_flag, inclusion: { in: [true, false] }
  validates :vote_weight, presence: true, numericality: { greater_than: 0 }
  validates :voter_id, uniqueness: { 
    scope: [:voter_type, :votable_id, :votable_type],
    message: "can only vote once per item" 
  }

  # Scopes
  scope :upvotes, -> { where(vote_flag: true) }
  scope :downvotes, -> { where(vote_flag: false) }
  scope :by_bots, -> { where(voter_type: 'Bot') }
  scope :by_users, -> { where(voter_type: 'User') }

  # Callbacks
  before_validation :set_default_weight, on: :create

  private

  def set_default_weight
    self.vote_weight ||= voter.try(:voter_weight) || 1.0
  end
end 