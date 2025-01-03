module Topics
  class QuotesController < ApplicationController
    before_action :authenticate
    before_action :set_topic

    def index
      @quotes = @topic.quotes.order(created_at: :desc)
    end

    def create
      @quote = @topic.quotes.build(quote_params)
      
      if @quote.save
        redirect_to send("#{@topic.class.name.underscore}_quotes_path", @topic), notice: "Quote was successfully added."
      else
        render :index, status: :unprocessable_entity
      end
    end

    private

    def set_topic
      @topic = Topic.friendly.find(params[:concept_id] || params[:person_id] || params[:place_id] || 
                                 params[:thing_id] || params[:event_id] || params[:action_id] || params[:other_id])
      
      unless @topic.type == params[:type]
        redirect_to root_path, alert: "Topic not found"
      end
    end

    def quote_params
      # Parse the metadata JSON if it's present
      params_with_parsed_metadata = params.require(:quote).tap do |quote_params|
        if quote_params[:metadata].present?
          quote_params[:metadata] = JSON.parse(quote_params[:metadata])
        end
      end

      params_with_parsed_metadata.permit(
        :content,
        :original_text, 
        :attribution_text, 
        :source_url, 
        :section_title, 
        :original_language,
        :wikiquote_section_id,
        :disputed,
        :misattributed,
        :citation,
        :context,
        metadata: {}  # Allow all metadata keys
      )
    end
  end
end 