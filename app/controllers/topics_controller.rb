class TopicsController < ApplicationController
  before_action :set_topic, only: [:show]

  def index
    # Get only topics with definitions, ordered by title
    @topics = Topic.joins(:definitions)
                  .includes(:definitions => [:source, :author])
                  .includes(:related_topics)
                  .distinct
                  .order(:title)
                  .group_by { |topic| topic.title[0].upcase }
    
    # Get unique first letters for navigation
    @letters = @topics.keys.sort
  end

  def show
    @quotes = @topic.fetch_quotes
    @gifs = GiphyService.search(@topic.title)
    @artworks = ArtsyService.new.search(@topic.title)
    @urban_definitions = UrbanDictionaryService.search(@topic.title)
    
    Rails.logger.info "Urban definitions found for #{@topic.title}: #{@urban_definitions.inspect}"
    
    # Redirect if accessed through wrong type's route
    unless params[:type] == @topic.type
      redirect_to polymorphic_path(@topic), status: :moved_permanently and return
    end
    
    type_template = @topic.type.underscore
    render type_template if lookup_context.exists?(type_template, ['topics'], true)
  end

  def search
    @query = params[:query].to_s.strip
    @topics = if @query.present? && @query.length >= 2
      Topic.search_by_title(@query)
           .includes(:definitions)
           .limit(10)
    else
      Topic.none
    end

    respond_to do |format|
      format.json do
        render json: @topics.map { |topic|
          {
            id: topic.id,
            title: topic.title,
            url: send("#{topic.route_key}_path", topic),
            part_of_speech: abbreviate_part_of_speech(topic.part_of_speech),
            definition: topic.definitions.first&.content&.to_plain_text&.truncate(100)
          }
        }
      end
    end
  rescue StandardError => e
    Rails.logger.error "Search error: #{e.message}\n#{e.backtrace.join("\n")}"
    render json: { error: "Search failed", message: e.message }, status: :internal_server_error
  end

  def refresh_quotes
    @topic = Topic.friendly.find(params[:id])
    @quotes = @topic.fetch_quotes
    
    respond_to do |format|
      format.turbo_stream {
        render turbo_stream: turbo_stream.replace(
          'quotes',
          partial: 'quotes',
          locals: { quotes: @quotes }
        )
      }
      format.html { redirect_to @topic }
    end
  end

  private

  def set_topic
    @topic = Topic.friendly.includes(:definitions => [:source, :author])
                  .includes(:related_topics)
                  .where(type: params[:type])
                  .find(params[:id])
  end

  def abbreviate_part_of_speech(pos)
    return nil unless pos
    case pos.to_s.downcase
    when 'noun' then 'n'
    when 'verb' then 'v'
    when 'adjective' then 'adj'
    when 'adverb' then 'adv'
    else pos.to_s[0..2]
    end
  end
end 