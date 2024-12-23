class Topic < ApplicationRecord
  # Enums
  enum :part_of_speech, {
    unknown: 0,
    noun: 1,
    verb: 2,
    adjective: 3,
    adverb: 4
  }, default: :unknown

  # Validations
  validates :title, presence: true, uniqueness: true
  validates :type, presence: true
  validates :conceptnet_id, uniqueness: true, allow_nil: true

  # Callbacks
  before_validation :set_conceptnet_id, if: -> { conceptnet_id.blank? }

  # Relationships
  has_many :topic_relationships, dependent: :destroy
  has_many :related_topics, through: :topic_relationships

  def refresh_conceptnet_data!
    self.conceptnet_id = nil
    set_conceptnet_id
    save!
  end

  def fetch_conceptnet_details
    return unless conceptnet_id
    data = ConceptNetService.lookup(title)
    return unless data

    {
      edges: data['edges'],
      weight: data.dig('weight'),
      related_terms: extract_related_terms(data)
    }
  end

  def update_conceptnet_relationships!
    details = fetch_conceptnet_details
    return unless details

    details[:related_terms].each do |term_data|
      # Find existing topic by ConceptNet ID
      related_topic = Topic.find_by(conceptnet_id: term_data[:id])
      next unless related_topic

      # Create relationship if it doesn't exist
      topic_relationships.find_or_create_by!(
        related_topic: related_topic,
        relationship_type: term_data[:relationship],
        weight: term_data[:weight]
      )
    end
  end

  def set_part_of_speech_from_conceptnet
    return unless conceptnet_data = ConceptNetService.lookup(title)
    
    # Look for explicit part of speech edges
    pos_edge = conceptnet_data['edges'].find do |e| 
      e['rel']['label'] == 'IsA' && 
      %w[noun verb adjective adverb].include?(e['end']['label'])
    end

    if pos_edge
      self.part_of_speech = pos_edge['end']['label']
    end
  end

  private

  def set_conceptnet_id
    return if title.blank?

    Rails.logger.info "Looking up ConceptNet data for: #{title}"
    concept_data = ConceptNetService.lookup(title)
    
    if concept_data && concept_data['@id'].present?
      Rails.logger.info "Found ConceptNet ID: #{concept_data['@id']}"
      self.conceptnet_id = concept_data['@id']
    else
      Rails.logger.info "No ConceptNet match found, using fallback"
      self.conceptnet_id = "/c/en/#{title.downcase.gsub(/\s+/, '_')}"
    end
  rescue StandardError => e
    Rails.logger.error "Error setting ConceptNet ID: #{e.message}"
    self.conceptnet_id = "/c/en/#{title.downcase.gsub(/\s+/, '_')}"
  end

  def extract_related_terms(data)
    return [] unless data['edges'].is_a?(Array)

    data['edges'].map do |edge|
      {
        id: edge['end']['@id'],
        label: edge['end']['label'],
        relationship: edge['rel']['label'],
        weight: edge['weight'] || 1.0
      }
    end.compact
  end
end 