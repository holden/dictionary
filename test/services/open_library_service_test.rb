require "test_helper"

class OpenLibraryServiceTest < ActiveSupport::TestCase
  test "fetches author data from OpenLibrary API" do
    VCR.use_cassette("openlibrary_author_search") do
      result = OpenLibraryService.search_author("Voltaire")
      
      assert_not_nil result
      assert_equal "Voltaire", result['name']
      assert_not_nil result['key']
    end
  end

  test "returns nil when author not found" do
    VCR.use_cassette("openlibrary_author_not_found") do
      result = OpenLibraryService.search_author("NonExistentAuthor123456789")
      
      assert_nil result
    end
  end

  test "searches for multiple authors" do
    VCR.use_cassette("openlibrary_authors_search") do
      results = OpenLibraryService.search_authors("Voltaire")
      
      assert_not_empty results
      assert_equal "Voltaire", results.first['name']
      assert_not_nil results.first['key']
    end
  end
end 