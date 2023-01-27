class MediaAttachment < ApplicationRecord
  belongs_to :post

  has_one_attached :file
  delegate_missing_to :file

  # There's no easy way to store ActiveStorage previews or variants in a reasonable
  # file structure when using an S3-compatible service; Rails sticks them all in the
  # root of the bucket, which is really messy. The easy way around this is to generate
  # and attach them as a separate file.
  #
  # To keep things simple for now, I'm only generating preview images for videos, but
  # I may eventually use it to store smaller thumbnails for regular images as well.
  has_one_attached :preview_image
  after_commit :generate_preview_image, if: :video?

  def width
    metadata[:width]
  end

  def height
    metadata[:height]
  end

  private

  def generate_preview_image
    return if preview_image.attached? && !file.blob.saved_changes?

    preview = file.preview(resize_to_limit: [width, height]).processed

    preview_image.attach(
      key: "blog/previews/#{id}.jpg",
      io: StringIO.new(preview.image.blob.download),
      filename: "#{id}.jpg",
      content_type: "image/jpeg"
    )

    preview.image.purge_later
  end
end
