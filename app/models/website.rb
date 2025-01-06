class Website < ApplicationRecord
  has_many :definitions, as: :source

  validates :title, presence: true
  validates :url, presence: true
end 