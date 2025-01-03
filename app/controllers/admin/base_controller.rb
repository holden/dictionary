module Admin
  class BaseController < ApplicationController
    include Authentication
    before_action :require_authentication
    layout 'admin'

    before_action do
      Rails.logger.info "=== ADMIN CONTROLLER HIT ==="
      Rails.logger.info "Layout being used: #{self.send(:_layout)}"
      Rails.logger.info "Current user: #{Current.user&.email_address}"
    end

    def current_page?(path)
      request.path == path
    end
    helper_method :current_page?
  end
end 