module Api
  module V1
    # JSON API base: bearer-token auth, JSON errors, no sessions, cookies or CSRF.
    class BaseController < ActionController::API
      include ActionController::HttpAuthentication::Token::ControllerMethods

      rate_limit to: 120, within: 1.minute, with: -> { render json: { error: "Too many requests" }, status: :too_many_requests }

      before_action :authenticate_token!

      rescue_from ActiveRecord::RecordNotFound do
        render json: { error: "Not found" }, status: :not_found
      end
      rescue_from ActionController::ParameterMissing do |error|
        render json: { error: error.message }, status: :bad_request
      end

      private

      def authenticate_token!
        token = authenticate_with_http_token { |plaintext, _options| ApiToken.authenticate(plaintext) }
        return request_authentication unless token

        token.touch_last_used
      end

      def request_authentication
        headers["WWW-Authenticate"] = 'Bearer realm="JobTrack"'
        render json: { error: "Missing or invalid API token" }, status: :unauthorized
      end
    end
  end
end
