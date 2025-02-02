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

  # Callbacks
  before_validation :standardize_title
  before_save :update_tsv, if: :will_save_change_to_title?
  after_create :ensure_external_ids
  after_commit :create_word_relationships, on: :create

  # Relationships
  has_many :topic_relationships, dependent: :destroy
  has_many :related_topics, through: :topic_relationships
  has_many :definitions, dependent: :destroy
  has_many :authored_definitions, 
           class_name: 'Definition',
           foreign_key: :source_id,
           dependent: :nullify
  has_many :quotes, dependent: :destroy
  has_many :lyrics, dependent: :destroy
  has_many :authored_quotes, 
           class_name: 'Quote',
           foreign_key: :author_id,
           dependent: :destroy

  # Add this if you want to search definitions too
  has_one :first_definition, -> { order(created_at: :asc) }, class_name: 'Definition'

  # Scopes
  scope :recent_first, -> { order(created_at: :desc) }

  has_and_belongs_to_many :people
  has_and_belongs_to_many :media, class_name: 'Media'

  # Add default scope to always include rich text content
  default_scope { includes(definitions: :rich_text_content) }
  
  # Or if you prefer not to use default_scope, modify your controller:
  scope :with_content, -> { includes(definitions: :rich_text_content) }

  def refresh_conceptnet_data!
    self.concept_net_id = nil
    generate_concept_net_id
    save!
  end

  def fetch_conceptnet_details
    return unless concept_net_id
    data = ConceptNetService.lookup(title)
    return unless data && data['edges'].is_a?(Array)

    {
      edges: data['edges'].select { |e| e['start'].is_a?(Hash) && e['end'].is_a?(Hash) },
      weight: data.dig('weight')
    }
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
    Rails.cache.delete("wikiquotes/#{title}") # Clear the specific cache key first
    WikiQuotesService.new(title).fetch_quotes
  end

  def display_title
    # Handle special cases first (e.g., "iOS", "iPhone")
    return SPECIAL_CASES[title.downcase] if SPECIAL_CASES.key?(title.downcase)
    
    title.titleize
  end

  # This runs only when a topic is first created
  def generate_concept_net_id
    return if concept_net_id.present?

    # Skip for authors/people
    return if type == "Person"

    # Try to get ConceptNet data
    if concept = ConceptNetService.lookup(title)
      self.concept_net_id = concept.fetch("id")
    end
  end

  # This is the only method that should handle relationships
  def update_relationships!
    Rails.logger.info "Creating relationships for '#{name}'"
    
    # Get related words from Datamuse
    related_words = DatamuseService.related_words(title)
    if related_words.empty?
      Rails.logger.info "No related words found for '#{title}'"
      return
    end

    # Get existing topics that match any of the related words
    existing_topics = Topic.where(
      title: related_words.map { |w| w['word'].downcase }
    ).pluck(:title, :id).to_h { |title, id| [title.downcase, id] }

    Rails.logger.info "Found #{existing_topics.size} matching topics for '#{title}'"

    ActiveRecord::Base.transaction do
      # Clear existing relationships
      topic_relationships.destroy_all

      # Find the maximum score for normalization
      max_score = related_words.map { |w| w['score'] }.max.to_f

      # Create new relationships for existing topics
      created = 0
      related_words.each do |word_data|
        word = word_data['word'].downcase
        next unless related_topic_id = existing_topics[word]
        next if related_topic_id == id # Skip self-relationships

        # Normalize score to be between 0 and 1
        normalized_weight = max_score.zero? ? 0.5 : word_data['score'] / max_score

        TopicRelationship.create!(
          topic: self,
          related_topic_id: related_topic_id,
          relationship_type: 'related',
          weight: normalized_weight
        )
        created += 1
      end

      Rails.logger.info "Created #{created} relationships for '#{title}'"
    end
  rescue StandardError => e
    Rails.logger.error "Error creating relationships for '#{name}': #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise e
  end

  # Add new callback for relationship creation
  def create_word_relationships
    Rails.logger.info "Scheduling relationship creation for Topic ##{id} (#{title})"
    CreateTopicRelationshipsJob.perform_later(id)
  end

  def fetch_johnson_definition
    # Skip if we already have a Johnson's definition
    return if definitions
      .joins('JOIN websites ON websites.id = definitions.source_id')
      .where(
        source_type: 'Website',
        websites: { title: 'Johnson\'s Dictionary' }
      ).exists?

    # Lookup the definition
    result = SamuelJohnsonService.lookup_definition(title)
    return unless result

    # Create the new definition with author
    definition = definitions.new(
      author: result[:author],
      source: result[:source],
      metadata: result[:metadata]
    )
    definition.content = result[:content_html]
    definition.save!
    definition

  rescue StandardError => e
    Rails.logger.error "Error fetching Johnson's definition for '#{title}': #{e.message}"
    nil
  end

  private

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
    return [] unless data['edges'].present?

    data['edges'].map do |edge|
      if edge['start'] == concept_net_id
        edge['end'].split('/').last
      else
        edge['start'].split('/').last
      end
    end.compact.uniq
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

  def ensure_external_ids
    ensure_concept_net_id unless type == 'Person'
    ensure_open_library_id if type == 'Person'
  end

  def ensure_concept_net_id
    return if concept_net_id.present?
    
    if concept = ConceptNetService.lookup(title)
      update_column(:concept_net_id, concept['@id'])
    end
  end

  def ensure_open_library_id
    return unless type == 'Person'
    return if open_library_id.present?

    if (author_data = OpenLibraryService.search_author(title))
      update(open_library_id: author_data[:open_library_id])
    end
  end
end 