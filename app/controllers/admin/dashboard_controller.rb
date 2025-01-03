module Admin
  class DashboardController < BaseController
    def index
      Rails.logger.info "=== ADMIN DASHBOARD HIT ==="
      @page_title = "Admin Dashboard"
    end
  end
end 