class Thing < Topic
  # Thing-specific behavior (formerly Object)
  def self.model_name
    Topic.model_name
  end
end 