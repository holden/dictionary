module Topics
  module People
    class SearchController < ApplicationController
      include Topics::TopicFinder
      
      before_action :authenticate
      before_action :set_topic
      
      def new
        @results = []
      end

      def create
        @results = TmdbService.new.search_people(params[:query])
        
        respond_to do |format|
          format.turbo_stream
          format.html { 
            if @results.any?
              render :new
            else
              redirect_to send("#{@topic.route_key}_people_path", @topic), 
                alert: "No results found for '#{params[:query]}'"
            end
          }
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