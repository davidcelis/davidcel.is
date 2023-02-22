class PhotosController < ApplicationController
  def index
    media = MediaAttachment.featured.includes(MediaAttachment::DEFAULT_INCLUDES).reorder(id: :desc)
    @pagy, @media_attachments = pagy(media, items: 24)
  end
end
