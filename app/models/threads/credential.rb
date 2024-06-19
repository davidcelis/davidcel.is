module Threads
  class Credential < ApplicationRecord
    self.table_name = "threads_credentials"

    class_attribute :oauth2_client, default: Threads::API::OAuth2::Client.new(
      client_id: Rails.application.credentials.dig(:threads, :client_id),
      client_secret: Rails.application.credentials.dig(:threads, :client_secret)
    )

    validates :access_token, presence: true
    validates :expires_at, presence: true

    encrypts :access_token

    def expired?
      expires_at.past?
    end

    def refresh!
      return if expired?

      response = oauth2_client.refresh_access_token(access_token)

      update!(
        access_token: response.access_token,
        expires_at: response.expires_in.to_i.seconds.from_now
      )
    end
  end
end
