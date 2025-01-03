class ApplicationController < ActionController::Base
  include Authentication
  helper_method :authenticated?
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  private

  def authenticated?
    Current.user.present?
  end
end
