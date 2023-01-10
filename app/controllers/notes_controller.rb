class NotesController < ApplicationController
  def index
    @pagy, @posts = pagy(Note.all)

    render "posts/index"
  end

  def show
    @note = Note.find(params[:id])
  end
end
