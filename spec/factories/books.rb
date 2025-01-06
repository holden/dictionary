FactoryBot.define do
  factory :book do
    title { "The Adventures of Tom Sawyer" }
    association :author, factory: :topic, type: 'Person'
    open_library_id { nil }
  end
end 