require "test_helper"

class PersonTest < ActiveSupport::TestCase
  test "validates presence of title" do
    person = Person.new
    assert_not person.valid?
    assert_includes person.errors[:title], "can't be blank"
  end

  test "validates_uniqueness_of_title" do
    existing_person = Person.create!(title: "Test Person")
    duplicate_person = Person.new(title: "Test Person")
    assert_not duplicate_person.valid?
  end
end 