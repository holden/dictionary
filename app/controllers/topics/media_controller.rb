module Topics
  class MediaController < ApplicationController
    include Topics::TopicFinder
    
    before_action :authenticate
    before_action :set_topic
    
    def index
      @media = @topic.media
    end

    def create
      @medium = ::Media.find_or_initialize_by(tmdb_id: media_params[:tmdb_id])
      @medium.assign_attributes(media_params)

      if @medium.save
        @topic.media << @medium unless @topic.media.include?(@medium)
        redirect_to send("#{@topic.route_key}_media_path", @topic), notice: "#{@medium.title} was successfully added."
      else
        redirect_to send("#{@topic.route_key}_media_path", @topic), alert: "Failed to add media."
      end
    end

    def destroy
      @medium = @topic.media.find(params[:id])
      @topic.media.delete(@medium)
      
      redirect_to send("#{@topic.route_key}_media_path", @topic), notice: "#{@medium.title} was successfully removed."
    end

    private

    def media_params
      params.require(:media).permit(:title, :type, :tmdb_id, metadata: {})
    end
  end
end 