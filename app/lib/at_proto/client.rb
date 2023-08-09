require "faraday"
require "faraday/retry"
require "faraday/multipart"

module ATProto
  class Client
    BASE_PATH = "/xrpc/com.atproto.repo".freeze
    IDENTITY_PATH = "/xrpc/com.atproto.identity".freeze
    IMAGE_SIZE_LIMIT = 976.56.kilobytes

    attr_reader :session

    def initialize(identifier:, password:)
      @session = ATProto::Session.new(identifier: identifier, password: password)
    end

    # Creates a post in the user's feed.
    #
    # @param text [String] The text of the post.
    # @param created_at [Time] The time the post was created.
    # @param images [Array] An Array of images to attach to the post, each as a Hash.
    # @option images [Hash] :image The image object to attach, as returned by upload_blob.
    # @option images [String] :alt The alt text for the image.
    def create_post(text:, created_at:, images: [])
      params = {
        "collection" => "app.bsky.feed.post",
        "repo" => @session.did,
        "record" => {
          "$type" => "app.bsky.feed.post",
          "text" => text,
          "facets" => parse_facets(text),
          "createdAt" => created_at.utc.iso8601(3)
        }
      }

      if images.any?
        params["record"]["embed"] = {
          "$type" => "app.bsky.embed.images",
          "images" => images
        }
      end

      connection.post("#{BASE_PATH}.createRecord", params.to_json)
    end

    # Uploads a blob to the user's repo.
    #
    # @param blob [String] The bytestream of the blob to upload.
    # @return [Hash] The response from the server. Example:
    #
    # {
    #   "blob": {
    #     "$type": "blob",
    #     "ref": {"$link": "bafkreihbmvgth3atknoy36na76htzbzsc7vlzocu2ynijcleikvvotm7cy"},
    #     "mimeType": "image/png",
    #     "size": 343459
    #   }
    # }
    def upload_blob(media_attachment, content_type:)
      response = nil

      media_attachment.open do |blob|
        tmpfile = ImageProcessor.process(blob, size_limit: IMAGE_SIZE_LIMIT)

        response = blob_upload_connection.post("#{BASE_PATH}.uploadBlob", tmpfile, "Content-Type" => content_type, "Content-Length" => tmpfile.size.to_s)
      end

      response.body
    end

    def sign_out!
      @session.destroy!
    end

    private

    def resolve_handle(handle)
      connection.get("#{IDENTITY_PATH}.resolveHandle", {handle: handle}).body["did"]
    end

    def parse_facets(text)
      facets = []

      # First, we'll look for any URLs in the post's text and create an unfurl.
      # To do this, we need to find not only the URLs themselves, but also the
      # start and end indices of each URL in the text.
      URI::DEFAULT_PARSER.extract(text, %w[http https]).each do |url|
        start_index = text.index(url)
        end_index = start_index + url.length

        facets << {
          "$type" => "app.bsky.richtext.facet",
          "features" => [{
            "$type" => "app.bsky.richtext.facet#link",
            "uri" => url
          }],
          "index" => {
            "byteStart" => start_index,
            "byteEnd" => end_index
          }
        }
      end

      # Then, we'll look for any @mentions of other Bluesky users. Unlike on
      # Mastodon, these will be formatted as @somebody.bsky.social, or even
      # just @somebodys.domain. We're essentially looking for valid domain
      # names prepended by an @ symbol.
      text.scan(Post::BLUESKY_MENTION_REGEX).each do |(handle)|
        start_index = text.index(handle) - 1 # 1 for the @ symbol.
        end_index = start_index + handle.length + 1 # 1 for the @ symbol.

        # We do, however, have to resolve the handle to a DID.
        did = resolve_handle(handle)

        facets << {
          "$type" => "app.bsky.richtext.facet",
          "features" => [{
            "$type" => "app.bsky.richtext.facet#mention",
            "did" => did
          }],
          "index" => {
            "byteStart" => start_index,
            "byteEnd" => end_index
          }
        }
      end

      facets
    end

    def connection
      @connection ||= Faraday.new(ATProto::BASE_URL) do |f|
        f.request :retry
        f.request :json
        f.request :authorization, "Bearer", @session.access_token

        f.response :raise_error
        f.response :json
      end
    end

    def blob_upload_connection
      @blob_upload_connection ||= Faraday.new(ATProto::BASE_URL) do |f|
        f.request :retry
        f.request :authorization, "Bearer", @session.access_token

        f.response :raise_error
        f.response :json
      end
    end
  end
end
