require "faraday"
require "faraday/retry"

module Mastodon
  class Client
    BASE_URL = "https://xoxo.zone"

    def initialize(access_token: Rails.application.credentials.dig(:mastodon, :access_token))
      @access_token = access_token
    end

    def verify_credentials
      connection.get("/api/v1/apps/verify_credentials").body
    end

    private

    def connection
      @connection ||= Faraday.new(BASE_URL) do |f|
        f.request :retry
        f.request :json
        f.request :authorization, "Bearer", @access_token

        f.response :raise_error
        f.response :json
      end
    end
  end
end
