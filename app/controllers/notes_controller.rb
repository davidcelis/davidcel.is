class NotesController < ApplicationController
  def index
    notes = Note.includes(Post::DEFAULT_INCLUDES)
    notes = notes.unscope(:order).search(params[:q]) if params[:q].present?

    @pagy, @posts = pagy(notes)

    render "posts/index"
  end

  def show
    @note = Note.includes(Post::DEFAULT_INCLUDES).find(params[:id])
  end
end
