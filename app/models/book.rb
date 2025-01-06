class Book < ApplicationRecord
  belongs_to :author, class_name: 'Topic'
  
  validates :title, presence: true
  validates :open_library_id, uniqueness: true, allow_nil: true

  after_create :ensure_open_library_id

  private

  def ensure_open_library_id
    return if open_library_id.present?
    
    if book = OpenLibraryService.lookup_book(title, author&.title)
      update_column(:open_library_id, book[:open_library_id])
    end
  end
end 