class QuotesController < ApplicationController
  before_action :authenticate

  def index
    @quotes = Quote.includes(:topic)
                  .order(created_at: :desc)
                  .page(params[:page])
                  .per(25)
  end

  def search
    @quotes = Quote.includes(:topic)
                  .where("content ILIKE ?", "%#{params[:q]}%")
                  .or(Quote.where("author ILIKE ?", "%#{params[:q]}%"))
                  .order(created_at: :desc)
                  .page(params[:page])
                  .per(25)
    render :index
  end
end 