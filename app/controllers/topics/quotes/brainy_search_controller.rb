module Topics
  module Quotes
    class BrainySearchController < ApplicationController
      before_action :authenticate
      before_action :set_topic

      def new
        @search_term = params[:q]
        @author = params[:author]
      end

      def create
        @search_term = search_params[:q]
        @author = search_params[:author]
        
        # Get raw results from BrainyQuotesService
        raw_results = BrainyQuotesService.search(search_params)
        
        # Deduplicate and clean up results
        @results = raw_results.uniq { |quote| 
          quote[:content].strip.downcase
        }.reject { |quote|
          quote[:content].blank?
        }

        # Filter by search term if provided
        if @search_term.present?
          @results = @results.select { |quote| 
            quote[:content].downcase.include?(@search_term.downcase)
          }
        end

        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              'search_results',
              partial: 'topics/quotes/brainy_search/results',
              locals: { results: @results, topic: @topic }
            )
          end
          format.html { render :new }
        end
      rescue BrainyQuotesService::Error => e
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
        params.permit(
          :q, :author, :namespace, :language,
          :type, :concept_id, :person_id, :place_id, :thing_id, :event_id, :action_id, :other_id,
          :commit, :authenticity_token
        )
      end
    end
  end
end 