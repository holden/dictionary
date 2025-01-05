require 'rails_helper'

RSpec.describe Topic, type: :model do
  describe 'creation and callbacks' do
    context 'when creating a new topic' do
      it 'downcases the title' do
        topic = Topic.create!(title: 'MONEY', type: 'Concept')
        expect(topic.title).to eq('money')
      end

      it 'maintains special case titles' do
        topic = Topic.create!(title: 'iPhone', type: 'Thing')
        expect(topic.title).to eq('iPhone')
      end
    end
  end

  describe 'external service integration' do
    context 'with ConceptNet' do
      let(:concept_net_response) do
        {
          '@id' => '/c/en/money',
          'edges' => [
            { 'start' => { '@id' => '/c/en/money' }, 'end' => { '@id' => '/c/en/currency' } }
          ]
        }
      end

      before do
        allow(ConceptNetService).to receive(:lookup)
          .with('money')
          .and_return(concept_net_response)
      end

      it 'fetches ConceptNet ID for non-Person topics' do
        topic = Topic.create!(title: 'money', type: 'Concept')
        expect(topic.concept_net_id).to eq('/c/en/money')
      end

      it 'does not fetch ConceptNet ID for Person topics' do
        topic = Topic.create!(title: 'ambrose bierce', type: 'Person')
        expect(topic.concept_net_id).to be_nil
      end
    end

    context 'with OpenLibrary' do
      let(:open_library_response) do
        {
          'key' => 'OL31757A',
          'name' => 'Ambrose Bierce',
          'birth_date' => '1842',
          'death_date' => '1914'
        }
      end

      before do
        allow(OpenLibraryService).to receive(:lookup_author)
          .with('ambrose bierce')
          .and_return(open_library_response)
      end

      it 'fetches OpenLibrary ID for Person topics' do
        topic = Topic.create!(title: 'ambrose bierce', type: 'Person')
        expect(topic.open_library_id).to eq('OL31757A')
      end

      it 'does not fetch OpenLibrary ID for non-Person topics' do
        topic = Topic.create!(title: 'money', type: 'Concept')
        expect(topic.open_library_id).to be_nil
      end
    end
  end

  describe 'relationships' do
    let(:datamuse_response) do
      [
        { 'word' => 'bank', 'score' => 500 },
        { 'word' => 'currency', 'score' => 400 },
        { 'word' => 'wealth', 'score' => 300 }
      ]
    end

    before do
      allow(DatamuseService).to receive(:related_words)
        .with('money')
        .and_return(datamuse_response)
    end

    it 'creates relationships with existing topics' do
      # Create some related topics first
      bank = Topic.create!(title: 'bank', type: 'Concept')
      currency = Topic.create!(title: 'currency', type: 'Concept')
      
      # Create our main topic
      money = Topic.create!(title: 'money', type: 'Concept')
      
      # Force relationship creation (normally handled by background job)
      money.update_relationships!

      # Check relationships were created
      expect(money.related_topics).to include(bank, currency)
      
      # Check weights were normalized
      bank_relationship = money.topic_relationships.find_by(related_topic: bank)
      expect(bank_relationship.weight).to eq(1.0) # Highest score normalized to 1
      
      currency_relationship = money.topic_relationships.find_by(related_topic: currency)
      expect(currency_relationship.weight).to eq(0.8) # 400/500 = 0.8
    end

    it 'schedules relationship creation after create' do
      expect {
        Topic.create!(title: 'money', type: 'Concept')
      }.to have_enqueued_job(CreateTopicRelationshipsJob)
    end
  end

  describe 'background job processing' do
    it 'processes relationships in the background' do
      topic = Topic.create!(title: 'money', type: 'Concept')
      
      expect {
        CreateTopicRelationshipsJob.perform_now(topic.id)
      }.to change { TopicRelationship.count }.by_at_least(1)
    end
  end
end 