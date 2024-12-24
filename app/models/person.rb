class Person < Topic
  # Person-specific behavior
  def self.model_name
    Topic.model_name
  end

  has_many :authored_definitions,
           class_name: 'Definition',
           as: :source,
           dependent: :nullify
end 