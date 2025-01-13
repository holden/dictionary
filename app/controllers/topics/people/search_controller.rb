module Topics
  module People
    class SearchController < ApplicationController
      before_action :authenticate
      before_action :set_topic
      
      def new
        @results = []
      end

      def create
        @results = TmdbService.new.search_people(params[:query])
        
        respond_to do |format|
          format.turbo_stream
          format.html { render :new }
        end
      end

      private

      def set_topic
        @topic = Topic.find_by!(slug: params[:concept_id])
      rescue ActiveRecord::RecordNotFound
        flash[:error] = "Topic not found"
        redirect_to root_path
      end
    end
  end
end 