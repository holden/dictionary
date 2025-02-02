module Topics
  module Lyrics
    class GeniusSearchController < ApplicationController
      include Topics::TopicFinder
      before_action :authenticate

      def new
      end

      def create
        @results = GeniusService.search(params[:query])
        
        respond_to do |format|
          format.turbo_stream {
            render turbo_stream: turbo_stream.update("search_results", 
              partial: "topics/lyrics/genius_search/result",
              locals: { results: @results })
          }
        end
      end

      private

      def search_params
        params.permit(:query)
      end
    end
  end
end 