module Threads
  class OAuthController < ApplicationController
    AUTHORIZATION_URL = "https://threads.net/oauth/authorize".freeze

    skip_before_action :verify_authenticity_token, only: [:callback]

    before_action :verify_state, only: [:callback]

    def initiate
      cookies.encrypted[:state] = SecureRandom.urlsafe_base64

      authorization_url = URI(AUTHORIZATION_URL)
      authorization_url.query = {
        client_id: Rails.application.credentials.dig(:threads, :client_id),
        redirect_uri: threads_oauth_callback_url,
        scope: "threads_basic,threads_content_publish,threads_read_replies,threads_manage_replies,threads_manage_insights",
        response_type: "code",
        state: cookies.encrypted[:state]
      }.to_query

      redirect_to authorization_url.to_s, allow_other_host: true
    end

    def callback
      redirect_to root_path and return if params[:code].blank?

      token_response = client.access_token(code: params[:code], redirect_uri: threads_oauth_callback_url)

      if token_response.error_type.present?
        flash.alert = "#{token_response.error_type} (#{token_response.error_message})"

        redirect_to root_path and return
      end

      # This first token is short-lived, so we'll immediately exchange it for a
      # long-lived token that we'll store in the database.
      token_response = client.exchange_access_token(token_response.access_token)
      token_attributes = {
        access_token: token_response.access_token,
        expires_at: token_response.expires_in.to_i.seconds.from_now
      }

      begin
        Credential.sole.update!(token_attributes)
      rescue ActiveRecord::RecordNotFound
        Credential.create!(token_attributes)
      end

      redirect_to root_path, notice: "Successfully authenticated with Threads!"
    end

    private

    def verify_state
      if cookies.encrypted[:state] != params[:state]
        flash.alert = "The provided OAuth state did not match. Please try again."

        redirect_to root_path
      end
    end

    def client
      Credential.oauth2_client
    end
  end
end
