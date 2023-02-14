class NotesController < ApplicationController
  def index
    @pagy, @posts = pagy(Note.includes(Post::DEFAULT_INCLUDES).viewable)

    render "posts/index"
  end

  def show
    @note = Note.find(params[:id])
  end
end
