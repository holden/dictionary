module Topics
  class MediaController < ApplicationController
    before_action :authenticate
    before_action :set_topic
    
    def index
      @media = @topic.media.order(created_at: :desc)
    end

    def create
      @medium = if media_params[:type] == 'Photo'
        Photo.find_or_initialize_by(unsplash_id: media_params[:unsplash_id])
      else
        Movie.find_or_initialize_by(tmdb_id: media_params[:tmdb_id])
      end

      @medium.assign_attributes({
        title: media_params[:title],
        metadata: media_params[:metadata]
      })

      if @medium.save
        @topic = find_topic
        @topic.media << @medium unless @topic.media.include?(@medium)
        
        respond_to do |format|
          format.html { redirect_to send("#{@topic.route_key}_media_path", @topic), notice: "#{@medium.title} was successfully added." }
          format.turbo_stream { 
            flash.now[:notice] = "#{@medium.title} was successfully added."
            @media = @topic.media.order(created_at: :desc)
            render turbo_stream: [
              turbo_stream.update("content", template: "topics/media/index"),
              turbo_stream.update("flash", partial: "shared/flash")
            ]
          }
        end
      else
        render :new, status: :unprocessable_entity
      end
    end

    def destroy
      @medium = @topic.media.find(params[:id])
      @topic.media.delete(@medium)

      respond_to do |format|
        format.html { redirect_to send("#{@topic.route_key}_media_path", @topic), notice: "Media was successfully removed." }
        format.turbo_stream { 
          flash.now[:notice] = "Media was successfully removed."
          render turbo_stream: [
            turbo_stream.remove(@medium),
            turbo_stream.update("flash", partial: "shared/flash")
          ]
        }
      end
    end

    private

    def set_topic
      param_key = case params[:type]&.downcase
        when 'concept' then :concept_id
        when 'place' then :place_id
        when 'thing' then :thing_id
        when 'event' then :event_id
        when 'action' then :action_id
        when 'other' then :other_id
        else
          raise ActionController::ParameterMissing, "Missing topic type parameter"
      end

      @topic = Topic.friendly.find(params[param_key])
      
      unless @topic.type.downcase == params[:type].downcase
        redirect_to root_path, alert: "Topic not found"
      end
    end

    def media_params
      params.require(:media).permit(
        :title,
        :type,
        :tmdb_id,
        :unsplash_id,
        metadata: {}
      )
    end

    def find_topic
      param_key = params[:type].underscore
      param_value = params["#{param_key}_id"]
      param_key.classify.constantize.find_by!(slug: param_value)
    end
  end
end 