class GeneratePreviewImageJob < ApplicationJob
  def perform(media_attachment_id)
    media_attachment = MediaAttachment.find(media_attachment_id)

    preview = media_attachment.file.preview(resize_to_limit: [media_attachment.width, media_attachment.height]).processed

    media_attachment.preview_image.attach(
      key: "blog/previews/#{media_attachment.id}.jpg",
      io: StringIO.new(preview.image.blob.download),
      filename: "#{media_attachment.id}.jpg",
      content_type: "image/jpeg"
    )

    media_attachment.update!(processed: true)

    preview.image.purge_later
  end
end
