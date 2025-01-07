require "test_helper"

class PersonTest < ActiveSupport::TestCase
  test "validates presence of title" do
    person = Person.new
    assert_not person.valid?
    assert_includes person.errors[:title], "can't be blank"
  end

  test "validates uniqueness of title" do
    existing = people(:mark_twain)
    person = Person.new(title: existing.title)
    assert_not person.valid?
    assert_includes person.errors[:title], "has already been taken"
  end
end 