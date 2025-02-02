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
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              'search_results',
              partial: 'topics/lyrics/genius_search/results',
              locals: { results: @results, topic: @topic }
            )
          end
        end
      end

      private

      def search_params
        params.permit(:query)
      end
    end
  end
end 