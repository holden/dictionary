require "test_helper"

class ConceptNetServiceTest < ActiveSupport::TestCase
  self.use_transactional_tests = false # Don't need database
  
  test "fetches concept data from ConceptNet API" do
    VCR.use_cassette('conceptnet/money_lookup') do
      result = ConceptNetService.lookup('money')
      assert result.key?('@id')
      assert_equal '/c/en/money', result['@id']
    end
  end
end 