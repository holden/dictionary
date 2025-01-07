module ApiCacheable
  extend ActiveSupport::Concern

  class_methods do
    def cache_api_response(cache_key, expires_in: 24.hours)
      Rails.cache.fetch(cache_key, expires_in: expires_in) do
        yield
      end
    end
  end
end 