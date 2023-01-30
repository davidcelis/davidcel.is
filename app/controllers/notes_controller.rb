class NotesController < ApplicationController
  def index
    @pagy, @posts = pagy(Note.includes(media_attachments: {file_attachment: :blob, preview_image_attachment: :blob}))

    render "posts/index"
  end

  def show
    @note = Note.find(params[:id])
  end
end
