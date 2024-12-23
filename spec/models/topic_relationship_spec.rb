require 'rails_helper'

RSpec.describe TopicRelationship, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:relationship_type) }
    it { should validate_numericality_of(:weight).is_greater_than(0).allow_nil }
  end

  describe 'associations' do
    it { should belong_to(:topic) }
    it { should belong_to(:related_topic).class_name('Topic') }
  end
end 