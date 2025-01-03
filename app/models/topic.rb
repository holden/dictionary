class Topic < ApplicationRecord
  extend FriendlyId
  friendly_id :slug_candidates, use: :slugged
  include PgSearch::Model
  
  pg_search_scope :search_by_title,
                  against: :title,
                  using: {
                    tsearch: { 
                      prefix: true,
                      dictionary: 'english',
                      tsvector_column: 'tsv'
                    }
                  }

  # Global search configuration for multisearch
  multisearchable against: [:title, :part_of_speech],
                  using: {
                    tsearch: {
                      prefix: true,
                      dictionary: 'english'
                    }
                  }

  # Define special cases as a class constant at the very top
  SPECIAL_CASES = {
    'ios' => 'iOS',
    'iphone' => 'iPhone',
    'google' => 'Google',
    'facebook' => 'Facebook',
    'nasa' => 'NASA',
    'fbi' => 'FBI',
    'nsa' => 'NSA',
    'cia' => 'CIA',
    'foia' => 'FOIA',
    'gmo' => 'GMO',
    'edm' => 'EDM',
    'ipo' => 'IPO'
  }.freeze

  # Add EngTagger as a class-level service
  class << self
    def tagger
      @tagger ||= EngTagger.new
    end
  end

  # Validations
  validates :title, presence: true, 
    uniqueness: { case_sensitive: false }
  validates :type, presence: true
  validates :conceptnet_id, uniqueness: true, allow_nil: true

  # Callbacks
  before_validation :generate_conceptnet_id, if: :new_record?
  before_validation :standardize_title
  after_create :schedule_conceptnet_lookup
  before_save :update_tsv, if: :will_save_change_to_title?

  # Relationships
  has_many :topic_relationships, dependent: :destroy
  has_many :related_topics, through: :topic_relationships
  has_many :definitions, dependent: :destroy
  has_many :authored_definitions, 
           class_name: 'Definition',
           foreign_key: :source_id,
           dependent: :nullify

  # Add this if you want to search definitions too
  has_one :first_definition, -> { order(created_at: :asc) }, class_name: 'Definition'

  # Scopes
  scope :recent_first, -> { order(created_at: :desc) }

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

  def to_param
    slug
  end

  # Override model_name to return the proper route key
  def self.model_name
    ActiveModel::Name.new(self, nil, self.name.split('::').last)
  end

  # Helper method to get the proper path
  def to_path
    case type
    when 'Person'
      [:person, self]
    when 'Place'
      [:place, self]
    when 'Concept'
      [:concept, self]
    when 'Thing'
      [:thing, self]
    when 'Event'
      [:event, self]
    when 'Action'
      [:action, self]
    else
      [:other, self]
    end
  end

  # Helper method to get the route key based on type
  def route_key
    case type
    when 'Person'
      :person
    when 'Place'
      :place
    when 'Concept'
      :concept
    when 'Thing'
      :thing
    when 'Event'
      :event
    when 'Action'
      :action
    else
      :other
    end
  end

  # Class method to fix existing records
  def self.standardize_all_titles!
    transaction do
      find_each do |topic|
        # Skip if already standardized
        next if topic.title == topic.title.downcase

        old_title = topic.title
        topic.title = topic.title.downcase
        if topic.save
          Rails.logger.info "Standardized title: '#{old_title}' -> '#{topic.title}'"
        else
          Rails.logger.error "Failed to standardize title for topic #{topic.id}: #{topic.errors.full_messages.join(', ')}"
        end
      end
    end
  end

  def fetch_quotes
    WikiQuotesService.new(title).fetch_quotes
  end

  def display_title
    # Handle special cases first (e.g., "iOS", "iPhone")
    return SPECIAL_CASES[title.downcase] if SPECIAL_CASES.key?(title.downcase)
    
    title.titleize
  end

  private

  def generate_conceptnet_id
    return if conceptnet_id.present?

    base_id = "/c/en/#{title.downcase.gsub(/[^a-z0-9_]/, '_')}"
    candidate_id = base_id
    counter = 1

    while Topic.exists?(conceptnet_id: candidate_id)
      candidate_id = "#{base_id}_#{counter}"
      counter += 1
    end

    self.conceptnet_id = candidate_id
  end

  def standardize_title
    # Handle special cases first (e.g., "iOS", "iPhone")
    return if SPECIAL_CASES.key?(title&.downcase)
    
    self.title = title&.downcase
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

  def slug_candidates
    [
      :title,
      [:title, :type],
      [:title, :type, -> { Topic.where(title: title).count }]
    ]
  end

  # Regenerate slug when title changes
  def should_generate_new_friendly_id?
    title_changed? || super
  end

  def update_tsv
    sanitized_title = ActiveRecord::Base.sanitize_sql_array(['?', title])
    self.tsv = Topic.connection.execute(
      "SELECT to_tsvector('english', #{sanitized_title})"
    ).first['to_tsvector']
  end
end 