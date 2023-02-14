require "faraday"
require "faraday/retry"
require "faraday/multipart"

module Mastodon
  class Client
    BASE_URL = "https://xoxo.zone"

    def initialize(access_token: Rails.application.credentials.dig(:mastodon, :access_token))
      @access_token = access_token
    end

    def create_status(content:, media_ids: [], idempotency_key: nil)
      headers = {"Idempotency-Key" => idempotency_key.to_s} if idempotency_key.present?
      params = {status: content, media_ids: media_ids}

      connection.post("/api/v1/statuses", params.to_json, headers).body
    end

    def upload_media(media_attachment)
      response = media_attachment.open do |tmpfile|
        file = Faraday::UploadIO.new(tmpfile.path, media_attachment.content_type)

        media_upload_connection.post("/api/v2/media", file: file, description: media_attachment.description)
      end

      # If the upload is large enough, it gets processed asynchronously. In that
      # case, we need to poll the API until the processing is done.
      if response.status == 202
        id = response.body["id"]

        sleep(1) until connection.get("/api/v1/media/#{id}").status != 206
      end

      response.body
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

    def media_upload_connection
      @media_upload_connection ||= Faraday.new(BASE_URL) do |f|
        f.request :retry
        f.request :multipart
        f.request :url_encoded
        f.request :authorization, "Bearer", @access_token

        f.response :raise_error
        f.response :json
      end
    end
  end
end
