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
        redirect_to send("#{@topic.route_key}_path", @topic), notice: "Quote was successfully added."
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
      params.require(:quote).permit(:content, :author, :source_url)
    end
  end
end 