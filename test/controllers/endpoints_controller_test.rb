require "test_helper"

class EndpointsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    @project = create(:project, user: @user)
    @endpoint = create(:endpoint, project: @project)
    sign_in_as(@user)
  end

  test "GET /projects/:project_id/endpoints/:id shows endpoint" do
    get project_endpoint_path(@project, @endpoint)
    assert_response :success
    assert_match @endpoint.name, response.body
  end

  test "GET /projects/:project_id/endpoints/:id with wrong project returns 404" do
    other_project = create(:project)
    other_endpoint = create(:endpoint, project: other_project)
    get project_endpoint_path(@project, other_endpoint)
    assert_response :not_found
  end

  test "GET /projects/:project_id/endpoints/new shows form" do
    get new_project_endpoint_path(@project)
    assert_response :success
  end

  test "POST /projects/:project_id/endpoints creates endpoint" do
    assert_difference "Endpoint.count", 1 do
      post project_endpoints_path(@project), params: {
        endpoint: { name: "New API", url: "https://api.example.com/test", http_method: "GET" }
      }
    end
    assert_redirected_to project_endpoint_path(@project, Endpoint.last)
    assert_equal "Endpoint added.", flash[:notice]
  end

  test "POST with invalid data re-renders form" do
    post project_endpoints_path(@project), params: {
      endpoint: { name: "", url: "not-a-url" }
    }
    assert_response :unprocessable_entity
  end

  test "GET /projects/:project_id/endpoints/:id/edit shows edit form" do
    get edit_project_endpoint_path(@project, @endpoint)
    assert_response :success
  end

  test "PATCH updates endpoint" do
    patch project_endpoint_path(@project, @endpoint), params: {
      endpoint: { name: "Updated Name" }
    }
    assert_redirected_to project_endpoint_path(@project, @endpoint)
    assert_equal "Updated Name", @endpoint.reload.name
  end

  test "PATCH with invalid data re-renders form" do
    patch project_endpoint_path(@project, @endpoint), params: {
      endpoint: { name: "", url: "bad" }
    }
    assert_response :unprocessable_entity
  end

  test "DELETE destroys endpoint" do
    assert_difference "Endpoint.count", -1 do
      delete project_endpoint_path(@project, @endpoint)
    end
    assert_redirected_to project_path(@project)
  end

  test "cannot access endpoint of another user's project" do
    other_user = create(:user)
    other_project = create(:project, user: other_user)
    other_endpoint = create(:endpoint, project: other_project)
    get project_endpoint_path(other_project, other_endpoint)
    assert_response :not_found
  end
end
