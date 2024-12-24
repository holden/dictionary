class Topic < ApplicationRecord
  # Add EngTagger as a class-level service
  class << self
    def tagger
      @tagger ||= EngTagger.new
    end
  end

  # Validations
  validates :title, presence: true, uniqueness: true
  validates :type, presence: true
  validates :conceptnet_id, uniqueness: true, allow_nil: true

  # Callbacks
  before_validation :set_conceptnet_id, if: -> { conceptnet_id.blank? }
  after_create :schedule_conceptnet_lookup

  # Relationships
  has_many :topic_relationships, dependent: :destroy
  has_many :related_topics, through: :topic_relationships
  has_many :definitions, dependent: :destroy
  has_many :authored_definitions, 
           class_name: 'Definition',
           foreign_key: :source_id,
           dependent: :nullify

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

    Rails.logger.info "Processing relationships for #{title}"

    # Also try querying for relationships where this term is the object
    query_uri = URI("#{ConceptNetService::BASE_URL}/query?end=/c/en/#{title.downcase.gsub(/\s+/, '_')}&rel=/r/IsA&limit=50")
    additional_data = ConceptNetService.new.make_request(query_uri)
    
    if additional_data && additional_data['edges']
      details[:related_terms] += extract_related_terms(additional_data)
    end
    
    details[:related_terms].each do |term_data|
      # Only look for existing topics
      related_topic = Topic.where.not(id: id)
                          .find_by("conceptnet_id LIKE ?", "#{term_data[:id]}%")
      
      # Skip if no existing topic found
      unless related_topic
        Rails.logger.debug "Skipping #{term_data[:label]}: no existing topic found"
        next
      end

      # Create bidirectional relationship
      Rails.logger.info "Creating bidirectional relationship between #{title} and #{related_topic.title}"
      create_bidirectional_relationship!(
        related_topic,
        term_data[:relationship],
        term_data[:weight]
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

  def relationship_summary
    topic_relationships.includes(:related_topic).map do |rel|
      {
        topic: rel.related_topic.title,
        type: rel.relationship_type,
        weight: rel.weight
      }
    end
  end

  # Add this method to create bidirectional relationships
  def create_bidirectional_relationship!(related_topic, relationship_type, weight)
    # Create forward relationship
    forward_rel = topic_relationships.find_or_create_by!(
      related_topic: related_topic,
      relationship_type: relationship_type,
      weight: weight
    )

    # Create inverse relationship
    inverse_type = inverse_relationship_type(relationship_type)
    inverse_rel = related_topic.topic_relationships.find_or_create_by!(
      related_topic: self,
      relationship_type: inverse_type,
      weight: weight
    )

    [forward_rel, inverse_rel]
  end

  # Add method to determine part of speech dynamically
  def part_of_speech
    return @part_of_speech if defined?(@part_of_speech)
    
    tagged = self.class.tagger.add_tags(title)
    @part_of_speech = case tagged
    when /\<vb|\<vbd|\<vbg|\<vbn|\<vbp|\<vbz/
      'verb'
    when /\<nn|\<nns|\<nnp|\<nnps/
      'noun'
    when /\<jj|\<jjr|\<jjs/
      'adjective'
    when /\<rb|\<rbr|\<rbs/
      'adverb'
    else
      'unknown'
    end
    
    Rails.logger.debug "EngTagger detected part of speech for '#{title}': #{@part_of_speech} (#{tagged})"
    @part_of_speech
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

  def normalize_title(title)
    # Capitalize first letter of each word, remove extra spaces
    title.strip
         .split(/\s+/)
         .map(&:capitalize)
         .join(' ')
  end

  def extract_related_terms(data)
    return [] unless data['edges'].is_a?(Array)

    Rails.logger.info "Processing #{data['edges'].size} edges for #{title}"
    
    data['edges'].map do |edge|
      # Get the IDs we're working with
      start_id = edge['start']['@id'].split('/')[0..3].join('/')  # Get base concept ID
      end_id = edge['end']['@id'].split('/')[0..3].join('/')      # Get base concept ID
      current_id = conceptnet_id || "/c/en/#{title.downcase.gsub(/\s+/, '_')}"
      
      # Skip non-English edges
      next unless edge['start']['language'] == 'en' && edge['end']['language'] == 'en'
      
      # We're particularly interested in IsA relationships
      relationship = edge['rel']['label']
      
      # Handle both incoming and outgoing edges
      if start_id == current_id
        {
          id: end_id,
          label: edge['end']['label'],
          relationship: relationship,
          weight: edge['weight'] || 1.0,
          direction: 'outgoing'
        }
      elsif end_id == current_id
        {
          id: start_id,
          label: edge['start']['label'],
          relationship: "#{relationship} of",
          weight: edge['weight'] || 1.0,
          direction: 'incoming'
        }
      end
    end.compact
  end

  def schedule_conceptnet_lookup
    ConceptNetLookupJob.perform_later(id)
  end

  def determine_topic_type(relationship)
    case relationship.downcase
    when /is a.*person/, /by/, /of person/
      'Person'
    when /is a.*place/, /located/, /location/
      'Place'
    when /is a.*event/, /happened/, /occurred/
      'Event'
    when /is a.*concept/, /means/, /similar/
      'Concept'
    when /used for/, /has a/, /part of/, /made of/
      'Thing'
    when /to/, /can/, /causes/
      'Action'
    else
      'Other'
    end
  end

  def inverse_relationship_type(relationship_type)
    case relationship_type.downcase
    when 'isa'
      'HasA'
    when 'hasa'
      'IsA'
    when /^is a/i
      "Contains a"
    when /^contains a/i
      "Is a"
    when /^part of/i
      "Has part"
    when /^has part/i
      "Part of"
    else
      "#{relationship_type} by"
    end
  end

  def part_of_speech_from_conceptnet
    return nil unless conceptnet_data = ConceptNetService.lookup(title)
    
    # Look for explicit part of speech edges
    pos_edge = conceptnet_data['edges'].find do |e| 
      e['rel']['label'] == 'IsA' && 
      %w[noun verb adjective adverb].include?(e['end']['label'])
    end

    if pos_edge
      pos = pos_edge['end']['label']
      Rails.logger.debug "ConceptNet detected part of speech for '#{title}': #{pos}"
      pos
    end
  end
end 