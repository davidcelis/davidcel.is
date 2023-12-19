class DirectUploadsController < ActiveStorage::DirectUploadsController
  before_action :require_authentication

  private

  def blob_args
    super.tap do |args|
      id = SnowflakeID.generate
      extension = Rack::Mime::MIME_TYPES.invert[args[:content_type]]

      args.merge!(key: "blog/#{id}#{extension}")
    end
  end

  def direct_upload_json(blob)
    blob.as_json(root: false, methods: :signed_id).merge(direct_upload: {
      url: blob.service_url_for_direct_upload,
      headers: blob.service_headers_for_direct_upload.merge("X-Amz-Acl" => "public-read")
    })
  end

  def require_authentication
    if cookies.encrypted[:github_user_id] != Rails.application.credentials.dig(:github, :user_id)
      render json: {error: "Not authenticated"}, status: :unauthorized
    end
  end
end
