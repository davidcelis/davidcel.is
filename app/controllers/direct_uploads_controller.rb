class DirectUploadsController < ActiveStorage::DirectUploadsController
  private

  def blob_args
    super.tap do |args|
      id = ActiveRecord::Base.connection.select_value("SELECT public.snowflake_id();")
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
end
