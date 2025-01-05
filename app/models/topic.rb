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
  has_many :quotes, dependent: :destroy
  has_many :authored_quotes, 
           class_name: 'Quote',
           foreign_key: :author_id,
           dependent: :destroy

  # Add this if you want to search definitions too
  has_one :first_definition, -> { order(created_at: :asc) }, class_name: 'Definition'

  # Scopes
  scope :recent_first, -> { order(created_at: :desc) }

  def refresh_conceptnet_data!
    self.conceptnet_id = nil
    generate_conceptnet_id
    save!
  end

  def fetch_conceptnet_details
    return unless conceptnet_id
    data = ConceptNetService.lookup(title)
    return unless data && data['edges'].is_a?(Array)

    {
      edges: data['edges'].select { |e| e['start'].is_a?(Hash) && e['end'].is_a?(Hash) },
      weight: data.dig('weight')
    }
  end

  def update_conceptnet_relationships!
    details = fetch_conceptnet_details
    return unless details

    Rails.logger.info "Processing relationships for #{title}"

    # Get ONLY our existing topics for matching
    existing_topics = Topic.pluck(:title, :id).to_h { |title, id| [title.downcase, id] }

    # Clear existing relationships for this topic
    topic_relationships.destroy_all

    # Process each edge, but ONLY create relationships with existing topics
    details[:edges].each do |edge|
      # Skip self-referential relationships
      next if edge['start'] == edge['end']

      # Get the term we want to relate to
      related_term = if edge['start'] == conceptnet_id
        edge['end']['label']
      else
        edge['start']['label']
      end

      # ONLY proceed if this term exists in our database
      related_topic_id = existing_topics[related_term.downcase]
      next unless related_topic_id

      # Create relationship only between existing topics
      TopicRelationship.create!(
        topic: self,
        related_topic_id: related_topic_id,
        relationship_type: edge['rel']['label'],
        weight: edge['weight']
      )
    end

    Rails.logger.info "Created #{topic_relationships.reload.count} relationships for #{title}"
  rescue StandardError => e
    Rails.logger.error "Error updating relationships for #{title}: #{e.message}"
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
  def generate_conceptnet_id
    return if conceptnet_id.present?

    # For authors/people, try OpenLibrary first
    if type == "Person"
      author_data = OpenLibraryService.lookup_author(title.downcase)
      if author_data.present?
        self.openlibrary_id = author_data.fetch("key")
      end
      return # Skip ConceptNet for authors
    end

    # For non-authors, just get the ConceptNet ID
    concept = ConceptNetService.lookup(title)
    if concept.present?
      self.conceptnet_id = concept.fetch("id")
    end
  end

  # This is the only method that should handle relationships
  def update_relationships!
    return unless conceptnet_id.present?
    
    # Get the ConceptNet data
    data = ConceptNetService.lookup(title)
    return unless data && data['edges'].is_a?(Array)

    # Get existing topics for matching
    existing_topics = Topic.pluck(:title, :id).to_h { |title, id| [title.downcase, id] }
    
    # Clear existing relationships
    topic_relationships.destroy_all

    # Only create relationships between existing topics
    data['edges'].each do |edge|
      next if edge['start'] == edge['end'] # Skip self-references
      
      related_term = if edge['start'] == conceptnet_id
        edge['end']['label']
      else
        edge['start']['label']
      end

      # Only create relationship if the topic exists
      if related_id = existing_topics[related_term.downcase]
        TopicRelationship.create!(
          topic: self,
          related_topic_id: related_id,
          relationship_type: edge['rel']['label'],
          weight: edge['weight']
        )
      end
    end
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
      if edge['start'] == conceptnet_id
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
end 