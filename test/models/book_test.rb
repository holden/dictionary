require "test_helper"

class BookTest < ActiveSupport::TestCase
  fixtures :people, :books  # Explicitly load required fixtures in correct order
  
  test "validates presence of title" do
    book = Book.new(author: people(:mark_twain))
    assert_not book.valid?
    assert_includes book.errors[:title], "can't be blank"
  end

  test "ensures open_library_id after create when lookup succeeds" do
    OpenLibraryService.stub :lookup_book, { open_library_id: "OL999999W" } do
      book = Book.create!(
        title: "Adventures of Huckleberry Finn",
        author: people(:mark_twain)
      )
      assert_equal "OL999999W", book.open_library_id
    end
  end
end 