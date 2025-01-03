module Topics
  module Quotes
    class SearchController < ApplicationController
      before_action :authenticate
      before_action :set_topic

      def new
        @search_term = params[:q]
        @author = params[:author]
        @namespace = params[:namespace]
      end

      def create
        @search_term = search_params[:q]
        @author = search_params[:author]
        @namespace = search_params[:namespace]
        
        @results = WikiquotesService.search(search_params)
        @pagy, @results = pagy_array(@results, items: 20)
        
        respond_to do |format|
          format.html { render :results }
          format.turbo_stream { 
            render turbo_stream: turbo_stream.update(
              'search_results',
              partial: 'topics/quotes/search/results_content',
              locals: { results: @results, pagy: @pagy, topic: @topic }
            )
          }
        end
      rescue WikiquotesService::Error => e
        flash.now[:alert] = "Search failed: #{e.message}"
        render :new, status: :unprocessable_entity
      end

      private

      def set_topic
        @topic = Topic.friendly.find(params[:concept_id] || params[:person_id] || params[:place_id] || 
                                   params[:thing_id] || params[:event_id] || params[:action_id] || params[:other_id])
        
        unless @topic.type == params[:type]
          redirect_to root_path, alert: "Topic not found"
        end
      end

      def search_params
        params.permit(:q, :author, :namespace).to_h.compact_blank
      end
    end
  end
end 