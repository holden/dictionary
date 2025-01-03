module Topics
  class QuotesController < ApplicationController
    before_action :authenticate
    before_action :set_topic
    before_action :set_quote, only: [:destroy]

    def index
      @quotes = @topic.quotes.order(created_at: :desc)
    end

    def create
      @quote = @topic.quotes.build(quote_params)
      
      if params[:quote][:author_name].present?
        begin
          author = AuthorLookupService.find_or_create_author(params[:quote][:author_name])
          @quote.author = author
        rescue AuthorLookupService::NotFoundError => e
          # Fall back to just using the attribution text
          @quote.attribution_text = params[:quote][:author_name]
        end
      elsif @quote.metadata.dig('wikiquote', 'author').present?
        # Try to get author from metadata if not explicitly provided
        author_name = @quote.metadata.dig('wikiquote', 'author').titleize
        begin
          author = AuthorLookupService.find_or_create_author(author_name)
          @quote.author = author
        rescue AuthorLookupService::NotFoundError => e
          @quote.attribution_text = author_name
        end
      end

      # If no author was found or provided, use the page title as attribution
      if @quote.author.nil? && @quote.attribution_text.blank?
        @quote.attribution_text = @quote.metadata.dig('wikiquote', 'page_title') || 'Anonymous'
      end

      if @quote.save
        redirect_to send("#{@topic.route_key}_quotes_path", @topic),
          notice: 'Quote was successfully created.'
      else
        render :new, status: :unprocessable_entity
      end
    end

    def destroy
      @quote.destroy
      
      respond_to do |format|
        format.html { redirect_to send("#{@topic.class.name.underscore}_quotes_path", @topic), notice: "Quote was successfully removed." }
        format.turbo_stream { 
          flash.now[:notice] = "Quote was successfully removed."
          render turbo_stream: [
            turbo_stream.remove(@quote),
            turbo_stream.update("flash", partial: "shared/flash")
          ]
        }
      end
    end

    private

    def set_quote
      @quote = @topic.quotes.find(params[:id])
    end

    def set_topic
      @topic = Topic.friendly.find(params[:concept_id] || params[:person_id] || params[:place_id] || 
                                 params[:thing_id] || params[:event_id] || params[:action_id] || params[:other_id])
      
      unless @topic.type == params[:type]
        redirect_to root_path, alert: "Topic not found"
      end
    end

    def quote_params
      # Parse the metadata JSON if it's a string
      params_with_parsed_metadata = params.require(:quote).tap do |quote_params|
        if quote_params[:metadata].is_a?(String)
          quote_params[:metadata] = JSON.parse(quote_params[:metadata])
        end
      end

      params_with_parsed_metadata.permit(
        :content, :source_url, :context, :citation,
        :said_on, :section_title, :wikiquote_section_id,
        :original_text, :original_language, :disputed,
        :misattributed, metadata: {}
      )
    end
  end
end 