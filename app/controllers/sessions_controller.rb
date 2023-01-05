class SessionsController < ApplicationController
  def new
    cookies.encrypted[:state] = SecureRandom.urlsafe_base64

    authorization_url = URI(GitHub::OAuthController::AUTHORIZATION_URL)
    authorization_url.query = {
      client_id: Rails.application.credentials.dig(:github, :client_id),
      redirect_uri: github_oauth_callback_url,
      state: cookies.encrypted[:state],
      login: "davidcelis",
      allow_signup: false
    }.to_query

    redirect_to authorization_url.to_s, allow_other_host: true
  end

  def destroy
    cookies.clear

    redirect_to root_path
  end
end
