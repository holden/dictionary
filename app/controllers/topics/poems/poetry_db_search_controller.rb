module Topics
  module Poems
    class PoetryDbSearchController < ApplicationController
      include Topics::TopicFinder
      before_action :authenticate

      def new
        @search_term = params[:q]
        @author = params[:author]
        
        if @search_term.present? || @author.present?
          @results = if @author.present?
            ::PoetryDbService.search_by_author(@author)
          else
            ::PoetryDbService.search_by_title(@search_term)
          end
        end

        respond_to do |format|
          format.html
          format.turbo_stream do
            render turbo_stream: turbo_stream.update(
              "search_results",
              partial: "topics/poems/poetry_db_search/results",
              locals: { results: @results || [] }
            )
          end
        end
      end

      def create
        # Implementation remains the same as in the PoemsController#create
      end
    end
  end
end 