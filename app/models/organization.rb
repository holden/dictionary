class Organization < Topic
  has_many :authored_definitions,
           class_name: 'Definition',
           as: :source,
           dependent: :nullify
end 