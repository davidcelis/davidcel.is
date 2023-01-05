module GitHub
  class OAuthController < ApplicationController
    API_VERSION = "2022-11-28".freeze

    AUTHORIZATION_URL = "https://github.com/login/oauth/authorize".freeze
    ACCESS_TOKEN_URL = "https://github.com/login/oauth/access_token".freeze
    USER_URL = "https://api.github.com/user"

    skip_before_action :verify_authenticity_token, only: [:callback]

    before_action :verify_state

    def callback
      redirect_to root_path and return if params[:code].blank?

      token_url = URI(ACCESS_TOKEN_URL)
      token_url.query = {
        client_id: Rails.application.credentials.dig(:github, :client_id),
        client_secret: Rails.application.credentials.dig(:github, :client_secret),
        code: params[:code],
        redirect_uri: github_oauth_callback_url,
        state: cookies.encrypted[:state]
      }.to_query

      token_response = Net::HTTP.post(token_url, "")
      token_response = Rack::Utils.parse_query(token_response.body)

      if token_response["error"].present?
        flash.alert = "#{token_response["error_description"]} (#{token_response["error"]})"

        redirect_to root_path and return
      end

      access_token = token_response["access_token"]

      headers = {
        "Authorization" => "Bearer #{access_token}",
        "X-GitHub-Api-Version" => API_VERSION
      }
      user_response = Net::HTTP.get(URI(USER_URL), headers)
      user_response = JSON.parse(user_response)

      if user_response["id"] == Rails.application.credentials.dig(:github, :user_id)
        cookies.permanent.encrypted[:github_user_id] = user_response["id"]
        cookies.permanent.encrypted[:github_username] = user_response["login"]
      end

      redirect_to root_path
    end

    private

    def verify_state
      if cookies.encrypted[:state] != params[:state]
        flash.alert = "The provided OAuth state did not match. Please try again."

        redirect_to root_path
      end
    end
  end
end
