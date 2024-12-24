class Website < ApplicationRecord
  has_many :definitions, as: :source

  validates :url, presence: true, uniqueness: true
  validates :url, format: URI::regexp(%w[http https])
end 