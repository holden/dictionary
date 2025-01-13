module Topics
  module Media
    class SearchController < ApplicationController
      include Topics::TopicFinder
      
      before_action :authenticate
      before_action :set_topic
      
      def new
        @results = []
      end

      def create
        @results = TmdbService.new.multi_search(params[:query])
        
        respond_to do |format|
          format.turbo_stream
          format.html { render :new }
        end
      end
    end
  end
end 