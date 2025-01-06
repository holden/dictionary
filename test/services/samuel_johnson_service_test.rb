require "test_helper"

class SamuelJohnsonServiceTest < ActiveSupport::TestCase
  test "lookup_definition returns definition data for valid term" do
    VCR.use_cassette("samuel_johnson/abdomen") do
      result = SamuelJohnsonService.lookup_definition("abdomen")
      
      assert result
      assert_kind_of Hash, result
      assert result[:text].present?
      assert result[:source_url].present?
      assert_includes result[:source_url], "abdomen"
    end
  end

  test "lookup_definition handles terms with spaces and punctuation" do
    VCR.use_cassette("samuel_johnson/adams_apple") do
      result = SamuelJohnsonService.lookup_definition("Adam's apple")
      
      assert result
      assert_kind_of Hash, result
      assert result[:text].present?
    end
  end

  test "lookup_definition returns nil for non-existent term" do
    VCR.use_cassette("samuel_johnson/nonexistent") do
      result = SamuelJohnsonService.lookup_definition("xyznonexistentterm")
      assert_nil result
    end
  end
end 