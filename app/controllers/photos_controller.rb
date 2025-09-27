class PhotosController < ApplicationController
  def index
    media = MediaAttachment.featured
      .joins(:post)
      .where.not(posts: {type: "CheckIn"})
      .includes(MediaAttachment::DEFAULT_INCLUDES)
      .reorder(id: :desc)

    @pagy, @media_attachments = pagy(media, items: 24)

    respond_to :html
  end
end
