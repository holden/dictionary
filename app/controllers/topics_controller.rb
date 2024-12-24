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
    @gifs = GiphyService.search(@topic.title)
    @artworks = ArtsyService.new.search(@topic.title)
    
    Rails.logger.info "Artworks found for #{@topic.title}: #{@artworks.size}"
    Rails.logger.debug "Artwork data: #{@artworks.inspect}"
    
    # Redirect if accessed through wrong type's route
    unless params[:type] == @topic.type
      redirect_to polymorphic_path(@topic), status: :moved_permanently and return
    end
    
    type_template = @topic.type.underscore
    render type_template if lookup_context.exists?(type_template, ['topics'], true)
  end

  private

  def set_topic
    @topic = Topic.friendly.includes(:definitions => [:source, :author])
                  .includes(:related_topics)
                  .where(type: params[:type])
                  .find(params[:id])
  end
end 