module Topics
  module Media
    class GiphySearchController < ApplicationController
      include Topics::TopicFinder
      before_action :authenticate

      def new
        if params[:query].present?
          @results = GiphyService.search(params[:query])
        else
          @results = []
        end
      end

      def create
        @gif = Gif.find_or_initialize_by(
          source_type: 'Giphy',
          source_id: gif_params[:source_id]
        ) do |gif|
          gif.title = gif_params[:title]
          gif.metadata = {
            poster_url: gif_params[:poster_url],
            giphy: gif_params[:metadata][:giphy]
          }
        end

        if @gif.save
          @topic.media << @gif unless @topic.media.include?(@gif)
          respond_to do |format|
            format.turbo_stream { 
              flash.now[:notice] = "Added #{@gif.title} to #{@topic.title}"
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

      def gif_params
        params.require(:media).permit(:title, :source_id, :source_type, :poster_url, metadata: { giphy: {} })
      end
    end
  end
end 