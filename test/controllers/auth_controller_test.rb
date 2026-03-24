require "test_helper"

class AuthControllerTest < ActionDispatch::IntegrationTest
  test "GET /users/sign_in renders login form" do
    get new_user_session_path
    assert_response :success
  end

  test "GET /users/sign_up renders registration form" do
    get new_user_registration_path
    assert_response :success
  end

  test "POST /users/sign_in with valid credentials signs in and redirects" do
    user = create(:user)
    post user_session_path, params: { user: { email: user.email, password: "password123" } }
    assert_redirected_to root_path
  end

  test "POST /users/sign_in with invalid credentials shows error" do
    post user_session_path, params: { user: { email: "bad@example.com", password: "wrong" } }
    assert_response :unprocessable_entity
  end

  test "DELETE /users/sign_out signs out" do
    user = create(:user)
    sign_in_as(user)
    delete destroy_user_session_path
    # Devise redirects to root_path after sign out (which then redirects to sign_in)
    assert_response :redirect
  end

  test "unauthenticated GET / redirects to sign in" do
    skip "ProjectsController added in feature/projects"
    get root_path
    assert_redirected_to new_user_session_path
  end

  test "POST /users registers a new user" do
    assert_difference "User.count", 1 do
      post user_registration_path, params: {
        user: { email: "new@example.com", password: "password123", password_confirmation: "password123" }
      }
    end
    assert_redirected_to root_path
  end
end
