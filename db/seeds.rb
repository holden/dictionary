# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Load all seed files
#Dir[Rails.root.join('db/seeds/*.rb')].sort.each do |file|
#  puts "Loading seed file: #{file}"
#  load file
#end

# Clear existing users first
User.destroy_all

# Create test user
User.create!(
  email_address: "holden@hey.com",
  password: "sawyer69",
  password_confirmation: "sawyer69"
)

puts "Created test user: holden@hey.com"
