class Concept < Topic
  # Concept-specific behavior
  def self.model_name
    Topic.model_name
  end
end 