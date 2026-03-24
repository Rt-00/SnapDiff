require "test_helper"

class ProjectTest < ActiveSupport::TestCase
  test "valid project" do
    assert build(:project).valid?
  end

  test "invalid without name" do
    project = build(:project, name: nil)
    assert_not project.valid?
    assert_includes project.errors[:name], "can't be blank"
  end

  test "name must be unique per user" do
    user = create(:user)
    create(:project, user: user, name: "Shared Name")
    dup = build(:project, user: user, name: "Shared Name")
    assert_not dup.valid?
    assert_includes dup.errors[:name], "already exists in your account"
  end

  test "same name allowed for different users" do
    create(:project, name: "Shared Name")
    other = build(:project, name: "Shared Name")
    assert other.valid?
  end

  test "belongs to user" do
    assert_respond_to build(:project), :user
  end

  test "has many endpoints" do
    assert_respond_to build(:project), :endpoints
  end

  test "ordered scope returns newest first" do
    user = create(:user)
    old_project = create(:project, user: user, created_at: 2.days.ago)
    new_project = create(:project, user: user, created_at: 1.hour.ago)
    assert_equal new_project, user.projects.ordered.first
    assert_equal old_project, user.projects.ordered.last
  end
end
