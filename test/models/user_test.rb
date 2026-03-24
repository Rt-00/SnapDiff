require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "valid user with email and password" do
    user = build(:user)
    assert user.valid?
  end

  test "invalid without email" do
    user = build(:user, email: nil)
    assert_not user.valid?
    assert_includes user.errors[:email], "can't be blank"
  end

  test "invalid with duplicate email" do
    create(:user, email: "dup@example.com")
    user = build(:user, email: "dup@example.com")
    assert_not user.valid?
    assert_includes user.errors[:email], "has already been taken"
  end

  test "invalid without password" do
    user = build(:user, password: nil, password_confirmation: nil)
    assert_not user.valid?
  end

  test "invalid with short password" do
    user = build(:user, password: "short", password_confirmation: "short")
    assert_not user.valid?
  end

  test "has many projects" do
    assert_respond_to build(:user), :projects
  end
end
