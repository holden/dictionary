require "test_helper"

class DatamuseServiceTest < ActiveSupport::TestCase
  self.use_transactional_tests = false # Don't need database
  
  test "fetches related words from Datamuse API" do
    VCR.use_cassette('datamuse/money_related') do
      results = DatamuseService.related_words('money')
      assert_kind_of Array, results
      assert results.first.key?('word')
      assert results.first.key?('score')
    end
  end
end 