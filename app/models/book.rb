class Book < ApplicationRecord
  belongs_to :author, class_name: 'Person'
  
  validates :title, presence: true
  validates :open_library_id, uniqueness: true, allow_nil: true

  after_create :ensure_open_library_id

  private

  def ensure_open_library_id
    result = OpenLibraryService.lookup_book(title, author.title)
    update(open_library_id: result['key']&.gsub('/works/', '')) if result
  end
end 