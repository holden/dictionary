class QuotesController < ApplicationController
  include Pagy::Backend
  before_action :authenticate

  def index
    @pagy, @quotes = pagy(
      Quote.includes(:topic, :author)
           .order(created_at: :desc),
      items: 25
    )
  end

  def search
    @pagy, @quotes = pagy(
      Quote.includes(:topic, :author)
           .where("content ILIKE ?", "%#{params[:q]}%")
           .or(Quote.where("attribution_text ILIKE ?", "%#{params[:q]}%"))
           .order(created_at: :desc),
      items: 25
    )
    render :index
  end
end 