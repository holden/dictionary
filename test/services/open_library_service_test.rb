require "test_helper"

class OpenLibraryServiceTest < ActiveSupport::TestCase
  self.use_transactional_tests = false # Don't need database
  
  test "fetches author data from OpenLibrary API" do
    VCR.use_cassette('openlibrary/ambrose_bierce') do
      result = OpenLibraryService.search_author('ambrose bierce')
      assert result.key?(:name)
      assert result.key?(:open_library_id)
      assert_includes result[:name], 'Bierce'
    end
  end
end 