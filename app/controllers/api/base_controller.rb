module Api
  class BaseController < ActionController::API
    before_action :authenticate_api_token!

    private

    def authenticate_api_token!
      token = request.headers["Authorization"]&.delete_prefix("Bearer ")&.strip
      @current_user = User.find_by_api_token(token)
      render json: { error: "Unauthorized" }, status: :unauthorized unless @current_user
    end

    def current_user
      @current_user
    end
  end
end
