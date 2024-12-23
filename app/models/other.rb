class Other < Topic
  # Fallback type behavior
  def self.model_name
    Topic.model_name
  end
end 