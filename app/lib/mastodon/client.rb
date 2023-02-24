require "faraday"
require "faraday/retry"
require "faraday/multipart"

module Mastodon
  class Client
    BASE_URL = "https://xoxo.zone"
    IMAGE_SIZE_LIMIT = 8.megabytes
    VIDEO_SIZE_LIMIT = 40
    VIDEO_PIXEL_LIMIT = 2_304_000

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
        elsif media_attachment.video?
          convert_video(blob, metadata: media_attachment.file.metadata)
        else
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

    def convert_video(blob, metadata:)
      result = blob

      # First, we need to downscale the video if it exceeds Mastodon's limit of
      # 2,304,000 pixels (roughly 1920x1200 either way) while maintaining the
      # correct aspect ratio.
      if metadata[:width] * metadata[:height] > VIDEO_PIXEL_LIMIT
        result = Tempfile.new(["video", ".mp4"])

        # Get the aspect ratio of the video and use it to calculate the new
        # dimensions, making sure that each dimension is divisible by 2.
        aspect_ratio = metadata[:width].to_f / metadata[:height]
        new_width = (Math.sqrt(VIDEO_PIXEL_LIMIT * aspect_ratio) / 2).floor * 2
        new_height = (Math.sqrt(VIDEO_PIXEL_LIMIT / aspect_ratio) / 2).floor * 2

        system(ffmpeg, "-y", "-i", blob.path, "-vf", "scale=#{new_width}:#{new_height}", result.path)
      end

      # Next, we'll compress the video using two-pass encoding if necessary.
      bitrate = (VIDEO_SIZE_LIMIT * 8000) / blob.metadata[:duration]
      bitrate -= 128 if metadata[:audio]
      buffer = (bitrate * 0.05).floor

      while File.size(result.path) > VIDEO_SIZE_LIMIT.megabytes
        # We'll use the video's duration and Mastodon's 40MB limit to determine
        # the target bitrate for two-pass compression, making sure to account
        # for a targeted 128k audio bitrate.
        #
        # https://trac.ffmpeg.org/wiki/Encode/H.264#twopass
        system(ffmpeg, "-y", "-i", blob.path, "-c:v", "libx264", "-b:v", "#{bitrate}k", "-pass", "1", "-an", "-f", "mp4", "/dev/null")
        system(ffmpeg, "-y", "-i", blob.path, "-c:v", "libx264", "-b:v", "#{bitrate}k", "-pass", "2", "-c:a", "aac", "-b:a", "128k", result.path)
        result.rewind

        # If the file is still too big, reduce the bitrate by 5% and try again.
        bitrate -= buffer
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

    def ffmpeg
      @ffmpeg ||= ActiveStorage::Previewer::VideoPreviewer.ffmpeg_path
    end
  end
end
