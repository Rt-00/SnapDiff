module DeviseHelpers
  def sign_in_as(user)
    post user_session_path, params: {
      user: { email: user.email, password: user.password }
    }
  end
end

ActiveSupport::TestCase.include DeviseHelpers
ActionDispatch::IntegrationTest.include DeviseHelpers
