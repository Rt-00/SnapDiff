module Api
  class BaseController < ActionController::API
    before_action :authenticate_api_token!

    private

    def authenticate_api_token!
      token = request.headers["Authorization"]&.delete_prefix("Bearer ")&.strip
      return unauthorized! if token.blank?

      user = User.find_by_api_token(token)
      return unauthorized! unless user
      return unauthorized! unless ActiveSupport::SecurityUtils.secure_compare(user.api_token, token)

      @current_user = user
    end

    def unauthorized!
      render json: { error: "Unauthorized" }, status: :unauthorized
    end

    def current_user
      @current_user
    end
  end
end
