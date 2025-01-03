module ApplicationHelper
  include Pagy::Frontend
  def gravatar_url_for(email_address)
    hash = Digest::MD5.hexdigest(email_address.downcase)
    "https://www.gravatar.com/avatar/#{hash}?s=200&d=mp"
  end
end
