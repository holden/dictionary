require "test_helper"

class TopicTest < ActiveSupport::TestCase
  # Don't load fixtures by default
  # fixtures :topics  # Only add if needed
  
  def setup
    @concept_net_response = {
      '@id' => '/c/en/money',
      'edges' => [
        { 'start' => { '@id' => '/c/en/money' }, 'end' => { '@id' => '/c/en/currency' } }
      ]
    }

    @open_library_response = {
      'key' => 'OL31757A',
      'name' => 'Ambrose Bierce',
      'birth_date' => '1842',
      'death_date' => '1914'
    }

    @datamuse_response = [
      { 'word' => 'bank', 'score' => 500 },
      { 'word' => 'currency', 'score' => 400 },
      { 'word' => 'wealth', 'score' => 300 }
    ]
  end

  test "downcases title on creation" do
    topic = Topic.create!(title: 'MONEY', type: 'Concept')
    assert_equal 'money', topic.title
  end

  test "maintains special case titles" do
    topic = Topic.create!(title: 'iPhone', type: 'Thing')
    assert_equal 'iPhone', topic.title
  end

  test "fetches ConceptNet ID for non-Person topics" do
    stub_service_call(ConceptNetService, :lookup, @concept_net_response) do
      topic = Topic.create!(title: 'money', type: 'Concept')
      assert_equal '/c/en/money', topic.concept_net_id
    end
  end

  test "does not fetch ConceptNet ID for Person topics" do
    VCR.use_cassette('openlibrary/ambrose_bierce') do
      topic = Topic.create!(title: 'ambrose bierce', type: 'Person')
      assert_nil topic.concept_net_id
    end
  end

  test "fetches OpenLibrary ID for Person topics" do
    author_data = {
      name: 'Ambrose Bierce',
      open_library_id: 'OL31757A',
      birth_date: '1842',
      death_date: '1914'
    }
    
    stub_service_call(OpenLibraryService, :search_author, author_data) do
      topic = Topic.create!(title: 'ambrose bierce', type: 'Person')
      assert_equal 'OL31757A', topic.open_library_id
    end
  end

  test "does not fetch OpenLibrary ID for non-Person topics" do
    topic = Topic.create!(title: 'money', type: 'Concept')
    assert_nil topic.open_library_id
  end

  test "creates relationships with existing topics" do
    stub_service_call(DatamuseService, :related_words, @datamuse_response) do
      # Create related topics first
      bank = Topic.create!(title: 'bank', type: 'Concept')
      currency = Topic.create!(title: 'currency', type: 'Concept')
      
      # Create main topic
      money = Topic.create!(title: 'money', type: 'Concept')
      money.update_relationships!

      # Check relationships
      assert_includes money.related_topics, bank
      assert_includes money.related_topics, currency

      # Check weights
      bank_relationship = money.topic_relationships.find_by(related_topic: bank)
      assert_equal 1.0, bank_relationship.weight

      currency_relationship = money.topic_relationships.find_by(related_topic: currency)
      assert_equal 0.8, currency_relationship.weight
    end
  end

  test "schedules relationship creation after create" do
    assert_enqueued_with(job: CreateTopicRelationshipsJob) do
      Topic.create!(title: 'money', type: 'Concept')
    end
  end

  test "processes relationships in background job" do
    topic = Topic.create!(title: 'money', type: 'Concept')
    
    # Create the related topics first
    bank = Topic.create!(title: 'bank', type: 'Concept')
    currency = Topic.create!(title: 'currency', type: 'Concept')
    
    stub_service_call(DatamuseService, :related_words, @datamuse_response) do
      assert_difference -> { TopicRelationship.count }, 2 do
        perform_enqueued_jobs do
          CreateTopicRelationshipsJob.perform_later(topic.id)
        end
      end
    end

    # Verify the relationships were created correctly
    assert_includes topic.reload.related_topics, bank
    assert_includes topic.related_topics, currency
  end

  test "fetch_johnson_definition creates new definition" do
    topic = topics(:one)
    
    stub_request(:post, "https://api.zyte.com/v1/extract")
      .to_return(
        status: 200,
        body: {
          'browserHtml' => <<~HTML
            <div>
              <headword>TEST WORD</headword>
              <span class="gramGrp pos">n.s.</span>
              <span class="etym">[Lat.]</span>
              <div class="sjddef">A test definition</div>
            </div>
          HTML
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
    
    assert_difference -> { topic.definitions.count } do
      topic.fetch_johnson_definition
    end
    
    definition = topic.definitions.last
    assert definition
    assert definition.content.present?
    assert_equal 'Website', definition.source_type
    assert_equal 'Johnson\'s Dictionary', definition.source.title
  end

  test "fetch_johnson_definition doesn't duplicate definitions" do
    topic = topics(:one)
    website = Website.find_or_create_by!(
      title: 'Johnson\'s Dictionary',
      url: 'https://johnsonsdictionaryonline.com'
    )
    
    # Create an existing Johnson definition
    topic.definitions.create!(
      content: "Existing definition",
      source: website
    )
    
    assert_no_difference -> { topic.definitions.count } do
      topic.fetch_johnson_definition
    end
  end
end
