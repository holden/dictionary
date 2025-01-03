module Admin
  class QuotesController < BaseController
    def index
      @quotes = Quote.includes(:topic)
                    .order(created_at: :desc)
                    .page(params[:page])
    end
  end
end 