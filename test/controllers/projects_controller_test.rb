require "test_helper"

class ProjectsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    @project = create(:project, user: @user)
    sign_in_as(@user)
  end

  test "GET /projects lists current user projects" do
    get projects_path
    assert_response :success
    assert_match @project.name, response.body
  end

  test "GET /projects does not show other users' projects" do
    other_project = create(:project)
    get projects_path
    assert_no_match other_project.name, response.body
  end

  test "GET /projects/:id shows project" do
    get project_path(@project)
    assert_response :success
    assert_match @project.name, response.body
  end

  test "GET /projects/:id with wrong user returns 404" do
    other_project = create(:project)
    get project_path(other_project)
    assert_response :not_found
  end

  test "GET /projects/new shows form" do
    get new_project_path
    assert_response :success
  end

  test "POST /projects creates project" do
    assert_difference "Project.count", 1 do
      post projects_path, params: { project: { name: "New Project", description: "Desc" } }
    end
    assert_redirected_to project_path(Project.last)
    assert_equal "Project created.", flash[:notice]
  end

  test "POST /projects with invalid data re-renders form" do
    post projects_path, params: { project: { name: "" } }
    assert_response :unprocessable_entity
  end

  test "GET /projects/:id/edit shows edit form" do
    get edit_project_path(@project)
    assert_response :success
  end

  test "PATCH /projects/:id updates project" do
    patch project_path(@project), params: { project: { name: "Updated Name" } }
    assert_redirected_to project_path(@project)
    assert_equal "Updated Name", @project.reload.name
  end

  test "PATCH /projects/:id with invalid data re-renders form" do
    patch project_path(@project), params: { project: { name: "" } }
    assert_response :unprocessable_entity
  end

  test "DELETE /projects/:id destroys project" do
    assert_difference "Project.count", -1 do
      delete project_path(@project)
    end
    assert_redirected_to projects_path
  end

  test "unauthenticated requests redirect to sign in" do
    delete destroy_user_session_path
    get projects_path
    assert_redirected_to new_user_session_path
  end
end
