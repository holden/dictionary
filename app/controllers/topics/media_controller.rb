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

      respond_to do |format|
        if @medium.save
          @topic.media << @medium unless @topic.media.include?(@medium)
          format.html { redirect_to send("#{@topic.route_key}_media_path", @topic), notice: "#{@medium.title} was successfully added." }
          format.turbo_stream { redirect_to send("#{@topic.route_key}_media_path", @topic), notice: "#{@medium.title} was successfully added." }
        else
          format.html { redirect_to send("#{@topic.route_key}_media_path", @topic), alert: "Failed to add media." }
          format.turbo_stream { redirect_to send("#{@topic.route_key}_media_path", @topic), alert: "Failed to add media." }
        end
      end
    end

    def destroy
      @medium = @topic.media.find(params[:id])
      @topic.media.delete(@medium)
      
      respond_to do |format|
        format.html { redirect_to send("#{@topic.route_key}_media_path", @topic), notice: "#{@medium.title} was successfully removed." }
        format.turbo_stream { 
          flash.now[:notice] = "#{@medium.title} was successfully removed."
          render turbo_stream: [
            turbo_stream.remove(@medium),
            turbo_stream.update("flash", partial: "shared/flash")
          ]
        }
      end
    end

    private

    def media_params
      params.require(:media).permit(:title, :type, :tmdb_id, metadata: {})
    end
  end
end 