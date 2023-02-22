require "faraday"
require "faraday/retry"
require "faraday/multipart"

module Mastodon
  class Client
    BASE_URL = "https://xoxo.zone"
    IMAGE_SIZE_LIMIT = 8.megabytes

    def initialize(access_token: Rails.application.credentials.dig(:mastodon, :access_token))
      @access_token = access_token
    end

    def create_status(content:, media_ids: [], idempotency_key: nil)
      headers = {"Idempotency-Key" => idempotency_key.to_s} if idempotency_key.present?
      params = {status: content, media_ids: media_ids}

      connection.post("/api/v1/statuses", params.to_json, headers).body
    end

    def upload_media(media_attachment)
      response = media_attachment.open do |blob|
        tmpfile = if media_attachment.image?
          compress_image(blob)
        else
          # TODO: Mastodon also limits video size, although to 40MB. I should
          # probably add support for compressing videos as well.
          blob
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

    def compress_image(blob)
      result = blob
      quality = 100

      while File.size(result.path) > IMAGE_SIZE_LIMIT
        # It might seem silly to start at 99% and work our way down by single
        # digits, but often even the first pass at 99% will result in a much
        # smaller size. This lets us post high quality images with, hopefully,
        # only a few passes of compression.
        quality -= 1

        result = ImageProcessing::Vips
          .source(blob.path)
          .saver(Q: quality, optimize_coding: true, trellis_quant: true)
          .call
      end

      result
    end

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
