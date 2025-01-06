require "test_helper"

class SamuelJohnsonServiceTest < ActiveSupport::TestCase
  test "lookup_definition returns nil for non-existent term" do
    VCR.use_cassette("samuel_johnson/nonexistent") do
      result = SamuelJohnsonService.lookup_definition("xyznonexistentterm")
      assert_nil result
    end
  end
end 