class User < ApplicationRecord
  has_secure_password
  
  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  
  has_many :sessions, dependent: :destroy
end
