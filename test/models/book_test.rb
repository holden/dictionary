require "test_helper"

class BookTest < ActiveSupport::TestCase
  fixtures :people, :books  # Load required fixtures

  test "ensures open_library_id after create when lookup succeeds" do
    VCR.use_cassette("openlibrary_book_lookup") do
      author = people(:voltaire)  # Assuming you have a Voltaire fixture
      book = Book.create!(
        title: "Candide",
        author: author
      )
      
      assert_not_nil book.open_library_id
      assert_equal "Candide", book.title
    end
  end

  test "saves without open_library_id when lookup fails" do
    VCR.use_cassette("openlibrary_book_lookup_fails") do
      author = people(:voltaire)  # Use the same fixture
      book = Book.create!(
        title: "NonExistentBook123456789",
        author: author
      )
      
      assert_nil book.open_library_id
      assert_equal "NonExistentBook123456789", book.title
    end
  end

  test "validates presence of author" do
    book = Book.new(title: "Some Title")
    assert_not book.valid?
    assert_includes book.errors[:author], "must exist"
  end
end 