require 'rails_helper'

RSpec.describe ConceptNetLookupJob, type: :job do
  describe '#perform' do
    let(:topic) { create(:thing, title: 'elephant') }

    it 'calls refresh_conceptnet_data! on the topic' do
      expect_any_instance_of(Topic).to receive(:refresh_conceptnet_data!)
      expect_any_instance_of(Topic).to receive(:update_conceptnet_relationships!)
      described_class.perform_now(topic.id)
    end
  end
end 