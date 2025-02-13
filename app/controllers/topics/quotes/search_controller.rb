module Topics
  module Quotes
    class SearchController < ApplicationController
      before_action :authenticate
      before_action :set_topic

      def new
        @search_term = params[:q]
        @author = params[:author]
        @namespace = params[:namespace]
        @language = params[:language] || 'english'
      end

      def create
        @search_term = search_params[:q]
        @author = search_params[:author]
        @namespace = search_params[:namespace]
        @language = search_params[:language] || 'english'
        
        # Get raw results from WikiQuotesService
        raw_results = WikiQuotesService.search(search_params)
        
        # Deduplicate and clean up results
        @results = raw_results.uniq { |quote| 
          # Use content as deduplication key
          quote[:content].strip.downcase
        }.reject { |quote|
          # Remove entries that are just metadata
          quote[:content].blank? || 
          quote[:content].match?(/^(See|Compare|Source|Note|Reference):/i)
        }

        respond_to do |format|
          format.html { render :results }
          format.turbo_stream { 
            render turbo_stream: turbo_stream.update(
              'search_results',
              partial: 'topics/quotes/search/results_content',
              locals: { results: @results, topic: @topic }
            )
          }
        end
      rescue WikiQuotesService::Error => e
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
        # Permit all expected parameters including route and form params
        params.permit(
          :q, :author, :namespace, :language,
          # Route params
          :type, :concept_id, :person_id, :place_id, :thing_id, :event_id, :action_id, :other_id,
          # Form params
          :commit, :authenticity_token
        ).to_h.compact_blank
      end
    end
  end
end 