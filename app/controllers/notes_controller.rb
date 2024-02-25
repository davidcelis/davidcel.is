class NotesController < ApplicationController
  def index
    notes = Note.includes(Post::DEFAULT_INCLUDES)
    notes = notes.unscope(:order).search(params[:q]) if params[:q].present?

    @pagy, @posts = pagy(notes)

    ActiveRecord::Precounter.new(@posts).precount(:likes, :reposts, :replies)

    render "posts/index", formats: [:html]
  end

  def show
    @note = Note.includes(Post::DEFAULT_INCLUDES).find(params[:id])

    respond_to :html
  end
end
