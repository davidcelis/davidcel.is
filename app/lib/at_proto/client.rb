require "faraday"
require "faraday/retry"
require "faraday/multipart"

module ATProto
  class Client
    BASE_PATH = "/xrpc/com.atproto.repo".freeze
    IDENTITY_PATH = "/xrpc/com.atproto.identity".freeze
    IMAGE_SIZE_LIMIT = 976.56.kilobytes
    IMAGE_PIXEL_LIMIT = 16_200_000

    attr_reader :session

    def initialize(identifier:, password:)
      @session = ATProto::Session.new(identifier: identifier, password: password)
    end

    # Creates a post in the user's feed.
    #
    # @param text [String] The text of the post.
    # @param created_at [Time] The time the post was created.
    # @param facets [Array] An Array of rich text facets to attach to the post, each as a Hash.
    # @param images [Array] An Array of images to attach to the post, each as a Hash.
    def create_post(text:, created_at:, facets: [], images: [], embed: nil)
      params = post_params(text: text, created_at: created_at, facets: facets, images: images, embed: embed)

      connection.post("#{BASE_PATH}.createRecord", params.to_json)
    end

    # Updates a post in the user's feed.
    #
    # @param rkey [String] The ID of the post to update.
    # @param text [String] The text of the post.
    # @param created_at [Time] The time the post was created.
    # @param facets [Array] An Array of rich text facets to attach to the post, each as a Hash.
    # @param images [Array] An Array of images to attach to the post, each as a Hash.
    def update_post(rkey, text:, created_at:, facets: [], images: [], embed: nil)
      params = post_params(text: text, created_at: created_at, facets: facets, images: images, embed: embed)
      params["rkey"] = rkey

      connection.post("#{BASE_PATH}.putRecord", params.to_json)
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
    def upload_blob(attachment)
      response = nil

      attachment.blob.open do |blob|
        tmpfile = ImageProcessor.process(blob, size_limit: IMAGE_SIZE_LIMIT, pixel_limit: IMAGE_PIXEL_LIMIT)

        response = blob_upload_connection.post("#{BASE_PATH}.uploadBlob", tmpfile, "Content-Type" => attachment.content_type, "Content-Length" => tmpfile.size.to_s)
      end

      response.body
    end

    def sign_out!
      @session.destroy!
    end

    def resolve_handle(handle)
      connection.get("#{IDENTITY_PATH}.resolveHandle", {handle: handle}).body["did"]
    end

    def extract_facets(text)
      facets = []

      # First, we'll look for any URLs in the post's text and create a link.
      # Doing this is a bit complicated and requires a few steps for each link:
      #
      # 1. Shorten the URL to 22 characters (excluding the scheme) followed by
      #    an ellipsis, to match the same look/feel as a Twitter/Mastodon link.
      # 2. Replace the URL in the text with the shortened version.
      # 3. Pull the start and end indices of the shortened link in the text.
      #
      # Then, all of this info is used to create a facet for the link.
      URI::DEFAULT_PARSER.extract(text, %w[http https]).each do |url|
        schemeless_url = url.gsub(%r{^https?://}, "")
        shortened_url = schemeless_url.truncate(23, omission: "…")
        text.sub!(url, shortened_url)

        start_index = text.byteindex(shortened_url)
        end_index = start_index + shortened_url.bytesize

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
        start_index = text.byteindex(handle) - 1 # 1 for the @ symbol.
        end_index = start_index + handle.bytesize + 1 # 1 for the @ symbol.

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

      [text, facets]
    end

    private

    def post_params(text:, created_at:, facets: [], images: [], embed: nil)
      params = {
        "collection" => "app.bsky.feed.post",
        "repo" => @session.did,
        "record" => {
          "$type" => "app.bsky.feed.post",
          "text" => text,
          "facets" => facets,
          "createdAt" => created_at.utc.iso8601(3)
        }
      }

      if embed
        params["record"]["embed"] = embed
      elsif images.any?
        params["record"]["embed"] = {
          "$type" => "app.bsky.embed.images",
          "images" => images
        }
      end

      params
    end

    def connection
      @connection ||= Faraday.new(ATProto::BASE_URL) do |f|
        f.request :retry
        f.request :json
        f.request :authorization, "Bearer", @session.access_token

        # f.response :raise_error
        f.response :json
      end
    end

    def blob_upload_connection
      @blob_upload_connection ||= Faraday.new(ATProto::BASE_URL) do |f|
        f.request :retry
        f.request :authorization, "Bearer", @session.access_token

        # f.response :raise_error
        f.response :json
      end
    end
  end
end
