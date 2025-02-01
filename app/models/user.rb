class User < ApplicationRecord
  has_secure_password
  
  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  
  has_many :votes, as: :voter, dependent: :destroy
  has_many :sessions, dependent: :destroy
  has_many :quotes, dependent: :nullify
end
