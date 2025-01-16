module Topics
  module Media
    class TmdbSearchController < ApplicationController
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
          format.html { 
            if @results.any?
              render :new
            else
              redirect_to send("#{@topic.route_key}_media_path", @topic), 
                alert: "No results found for '#{params[:query]}'"
            end
          }
        end
      end
    end
  end
end 