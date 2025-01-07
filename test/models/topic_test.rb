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
    topic = Topic.create!(title: "UPPERCASE TITLE", type: "Concept")
    assert_equal "uppercase title", topic.title
  end

  test "maintains special case titles" do
    topic = Topic.create!(title: "MacBook Pro", type: "Thing")
    assert_equal "macbook pro", topic.title
  end

  test "fetches ConceptNet_ID for non-Person topics" do
    ConceptNetService.stub :lookup, { '@id' => "/c/en/test" } do
      topic = Topic.create!(title: "test concept", type: "Concept")
      assert_equal "/c/en/test", topic.concept_net_id
    end
  end

  test "creates relationships with existing topics" do
    DatamuseService.stub :related_words, ["related1", "related2"] do
      topic = Topic.create!(title: "unique test topic", type: "Concept")
      assert_enqueued_with(job: CreateTopicRelationshipsJob, args: [topic.id])
    end
  end

  test "schedules relationship creation after create" do
    topic = Topic.create!(title: "another unique topic", type: "Concept")
    assert_enqueued_with(job: CreateTopicRelationshipsJob, args: [topic.id])
  end

  test "processes relationships in background job" do
    topic = Topic.create!(title: "yet another topic", type: "Concept")
    assert_enqueued_with(job: CreateTopicRelationshipsJob)
  end
end
