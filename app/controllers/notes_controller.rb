class NotesController < ApplicationController
  def index
    @pagy, @posts = pagy(Note.includes(Post::DEFAULT_INCLUDES))
    @posts = Note.filter_posts_with_unprocessed_media(@posts)

    render "posts/index"
  end

  def show
    @note = Note.find(params[:id])
  end
end
