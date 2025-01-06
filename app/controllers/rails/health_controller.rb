module Rails
  class HealthController < ActionController::Base
    def show
      render html: "ok"
    end
  end
end 