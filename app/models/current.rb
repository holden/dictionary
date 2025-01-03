class Current < ActiveSupport::CurrentAttributes
  attribute :session
  attribute :user
  attribute :user_agent, :ip_address

  delegate :user, to: :session, allow_nil: true
end
