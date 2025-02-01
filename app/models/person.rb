class Person < ApplicationRecord
  has_and_belongs_to_many :topics
  has_many :quotes
  has_many :books
  has_many :bot_influences, dependent: :destroy
  has_many :influenced_bots, through: :bot_influences, source: :bot

  validates :title, presence: true, uniqueness: true
  validates :google_knowledge_id, uniqueness: { allow_nil: true }
  validates :tmdb_id, uniqueness: { allow_nil: true }
  validates :open_library_id, uniqueness: { allow_nil: true }

  extend FriendlyId
  friendly_id :title, use: :slugged

  def display_name
    title
  end

  def image_url
    metadata.dig('knowledge_graph', 'image_url') ||
    metadata.dig('tmdb', 'profile_path') ||
    'https://placehold.co/400x600/png?text=No+Preview'
  end

  def description
    metadata.dig('knowledge_graph', 'description') ||
    metadata.dig('tmdb', 'biography') ||
    metadata.dig('openlibrary', 'bio')
  end
end 