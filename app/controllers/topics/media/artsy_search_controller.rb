module Topics
  module Media
    class ArtsySearchController < ApplicationController
      before_action :authenticate
      before_action :set_topic

      def new
        if params[:query].present?
          @results = ArtsyService.new.search(params[:query])
        else
          @results = []
        end
      end

      def create
        @art = Art.find_or_initialize_by(source_type: 'Artsy', source_id: art_params[:source_id]) do |art|
          art.title = art_params[:title]
          art.metadata = {
            poster_url: art_params[:poster_url],
            artsy: art_params[:metadata][:artsy]
          }
        end

        if @art.save
          @topic.media << @art unless @topic.media.include?(@art)
          respond_to do |format|
            format.turbo_stream { 
              flash.now[:notice] = "Added #{@art.title} to #{@topic.title}"
              @media = @topic.media.order(created_at: :desc)
              render turbo_stream: [
                turbo_stream.update("content", template: "topics/media/index"),
                turbo_stream.update("flash", partial: "shared/flash")
              ]
            }
            format.html { redirect_to send("#{@topic.route_key}_media_path", @topic) }
          end
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

      def art_params
        params.require(:media).permit(:title, :source_id, :source_type, :poster_url, metadata: { artsy: {} })
      end
    end
  end
end 