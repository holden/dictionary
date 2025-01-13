module Topics
  module Media
    class SearchController < ApplicationController
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

      private

      def set_topic
        @topic = Topic.find_by!(slug: params[:concept_id])
      end
    end
  end
end 