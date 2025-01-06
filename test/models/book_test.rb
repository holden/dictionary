require "test_helper"

class BookTest < ActiveSupport::TestCase
  fixtures :all  # This loads all fixtures
  # Or specifically:
  # fixtures :books, :topics

  test "validates presence of title" do
    book = Book.new
    assert_not book.valid?
    assert_includes book.errors[:title], "can't be blank"
  end

  test "validates uniqueness of open_library_id" do
    existing_book = books(:one)
    book = Book.new(open_library_id: existing_book.open_library_id)
    assert_not book.valid?
    assert_includes book.errors[:open_library_id], "has already been taken"
  end

  test "belongs to author" do
    book = books(:one)
    assert_respond_to book, :author
    assert book.author.kind_of?(Topic), "Expected author to be a Topic or its subclass"
  end

  test "ensures open_library_id after create when lookup succeeds" do
    author = topics(:mark_twain)
    book_params = { 
      title: "The Adventures of Tom Sawyer",
      author: author
    }

    OpenLibraryService.stub :lookup_book, mock_open_library_response do
      book = Book.create!(book_params)
      assert_equal "OL123456W", book.reload.open_library_id
    end
  end

  test "does not update open_library_id when lookup fails" do
    author = topics(:mark_twain)
    book_params = { 
      title: "The Adventures of Tom Sawyer",
      author: author
    }

    OpenLibraryService.stub :lookup_book, nil do
      book = Book.create!(book_params)
      assert_nil book.reload.open_library_id
    end
  end

  test "does not call OpenLibrary service when open_library_id exists" do
    author = topics(:mark_twain)
    book_params = { 
      title: "The Adventures of Tom Sawyer",
      author: author,
      open_library_id: "existing_id"
    }

    OpenLibraryService.stub :lookup_book, -> { raise "Should not be called" } do
      assert_nothing_raised do
        Book.create!(book_params)
      end
    end
  end

  private

  def mock_open_library_response
    {
      title: "The Adventures of Tom Sawyer",
      author_names: ["Mark Twain"],
      open_library_id: "OL123456W",
      isbn: "0123456789",
      raw_data: { some: "data" }
    }
  end
end 