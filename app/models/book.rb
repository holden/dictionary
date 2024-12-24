class Book < ApplicationRecord
  belongs_to :author, class_name: 'Topic', optional: true
  has_many :definitions, as: :source

  validates :title, presence: true
  validates :openlibrary_id, uniqueness: true, allow_nil: true

  after_create :fetch_openlibrary_data

  private

  def fetch_openlibrary_data
    return if openlibrary_id.present?

    if (book_data = OpenLibraryService.search(title))
      # Create or find author if provided
      if book_data[:author_name].present?
        self.author = Topic.find_or_create_by!(
          title: book_data[:author_name],
          type: 'Person'
        )
      end

      update!(
        openlibrary_id: book_data[:openlibrary_id],
        published_date: book_data[:published_date]
      )
    end
  rescue => e
    Rails.logger.error "Error fetching OpenLibrary data: #{e.message}"
  end
end 