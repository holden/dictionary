require "test_helper"
require "vcr"

class SamuelJohnsonServiceTest < ActiveSupport::TestCase
  def setup
    @valid_response = {
      'browserHtml' => <<~HTML
        <div>
          <headword>ABDO'MEN.</headword>
          <span class="gramGrp pos">n.s.</span>
          <span class="etym">[Lat. from abdo, to hide.]</span>
          <div class="sjddef">A cavity commonly called the lower venter or belly...</div>
          <quotebibl>
            <quote>The abdomen consists of parts containing and contained.</quote>
            <span class="author"><em>Wiseman's</em></span>
            <span class="title"><em>Surgery</em></span>
          </quotebibl>
        </div>
      HTML
    }

    # Clear the cache before each test
    Rails.cache.clear
  end

  test "lookup_definition returns definition data for valid term" do
    stub_request(:post, "https://api.zyte.com/v1/extract")
      .to_return(
        status: 200,
        body: @valid_response.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    result = SamuelJohnsonService.lookup_definition("abdomen")
    
    assert result
    assert_kind_of Hash, result
    assert_equal "ABDO'MEN.", result[:headword]
    assert_equal "n.s.", result[:part_of_speech]
    assert_equal "[Lat. from abdo, to hide.]", result[:etymology]
    assert result[:definition].present?
    assert_equal 1, result[:quotes].size
    assert_includes result[:quotes].first[:text], "abdomen"
  end

  test "lookup_definition handles terms with spaces and punctuation" do
    stub_request(:post, "https://api.zyte.com/v1/extract")
      .to_return(
        status: 200,
        body: @valid_response.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    result = SamuelJohnsonService.lookup_definition("Adam's apple")
    
    assert result
    assert_kind_of Hash, result
    assert result[:definition].present?
  end

  test "lookup_definition returns nil for non-existent term" do
    stub_request(:post, "https://api.zyte.com/v1/extract")
      .to_return(
        status: 200,
        body: { 'browserHtml' => '<div>No results found</div>' }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    result = SamuelJohnsonService.lookup_definition("xyznonexistentterm")
    assert_nil result
  end

  test "lookup_definition uses caching" do
    normalized_term = "test"  # This matches what normalize_term will produce
    cache_key = "johnson_dictionary/#{normalized_term}"
    
    cached_result = {
      headword: "TEST",
      part_of_speech: "n.s.",
      etymology: "[Lat.]",
      definition: "A cached definition",
      quotes: [],
      image_url: "https://johnsonsdictionaryonline.com/img/words/f1773-#{normalized_term}-1.png",
      raw_data: "<div>Test</div>",
      content_html: "<div>Test</div>",
      metadata: {
        johnson_dictionary: {
          headword: "TEST",
          part_of_speech: "n.s.",
          etymology: "[Lat.]",
          quotes: [],
          image_urls: {
            '1755' => "https://johnsonsdictionaryonline.com/img/words/f1755-#{normalized_term}-1.png",
            '1773' => "https://johnsonsdictionaryonline.com/img/words/f1773-#{normalized_term}-1.png"
          },
          raw_html: "<div>Test</div>",
          extracted_at: Time.current.iso8601
        }
      }
    }.deep_stringify_keys  # Convert all keys to strings for consistent comparison

    # Clear the cache first
    Rails.cache.clear
    assert_nil Rails.cache.read(cache_key), "Cache should be empty"

    # Write to cache using the normalized term
    Rails.logger.debug "Writing to cache with key: #{cache_key}"
    success = Rails.cache.write(cache_key, cached_result)
    assert success, "Cache write should succeed"

    # Verify the cache write worked
    cached_value = Rails.cache.read(cache_key)
    assert_equal cached_result, cached_value, "Cache write failed"

    # Test with a term that will normalize to the same value
    result = SamuelJohnsonService.lookup_definition("TEST")
    assert_equal cached_result, result.deep_stringify_keys, "Cache read returned unexpected result"

    # Verify no HTTP request was made
    assert_not_requested :post, "https://api.zyte.com/v1/extract"
  end
end 