module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :set_current_request_details
    before_action :authenticate
  end

  private
    def set_current_request_details
      Current.user_agent = request.user_agent
      Current.ip_address = request.ip
    end

    def authenticate
      if session_id = cookies.signed[:session_id]
        Current.session = Session.find_by(id: session_id)
      end
    end

    def login(user)
      session = user.sessions.create!
      cookies.signed.permanent[:session_id] = session.id
      Current.session = session
    end

    def logout
      Current.session&.destroy
      cookies.delete(:session_id)
      Current.session = nil
    end
end
