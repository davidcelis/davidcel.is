require "faraday"
require "faraday/retry"
require "faraday/multipart"

module Mastodon
  class Client
    BASE_URL = Rails.application.credentials.dig(:mastodon, :url)

    IMAGE_SIZE_LIMIT = 16.megabytes
    IMAGE_PIXEL_LIMIT = 33_177_600 # 7680x4320px
    VIDEO_SIZE_LIMIT = 99
    VIDEO_PIXEL_LIMIT = 8_294_400 # 3840x2160px

    def initialize(access_token: Rails.application.credentials.dig(:mastodon, :access_token))
      @access_token = access_token
    end

    def create_status(content:, media_ids: [], idempotency_key: nil)
      headers = {"Idempotency-Key" => idempotency_key.to_s} if idempotency_key.present?
      params = {status: content, media_ids: media_ids}

      connection.post("/api/v1/statuses", params.to_json, headers).body
    end

    def update_status(id, content:, media_ids: [], idempotency_key: nil)
      params = {status: content, media_ids: media_ids}

      connection.put("/api/v1/statuses/#{id}", params.to_json).body
    end

    def delete_status(id)
      connection.delete("/api/v1/statuses/#{id}")
    end

    def upload_media(media_attachment)
      response = media_attachment.open do |blob|
        tmpfile = blob

        if media_attachment.image?
          tmpfile = ImageProcessor.process(tmpfile, size_limit: IMAGE_SIZE_LIMIT, pixel_limit: IMAGE_PIXEL_LIMIT)
        elsif media_attachment.video?
          metadata = media_attachment.file.metadata.slice(:width, :height, :duration, :audio).symbolize_keys
          tmpfile = VideoProcessor.process(tmpfile, size_limit: VIDEO_SIZE_LIMIT, pixel_limit: VIDEO_PIXEL_LIMIT, **metadata)
        end

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
