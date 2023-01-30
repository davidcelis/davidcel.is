class PostsController < ApplicationController
  before_action :require_authentication, only: [:create]

  def index
    @pagy, @posts = pagy(Post.includes(media_attachments: {file_attachment: :blob, preview_image_attachment: :blob}))
  end

  def show
    @post = Post.find(params[:id])

    instance_variable_set("@#{@post.type.underscore}", @post)

    render "#{@post.type.tableize}/show"
  end

  def create
    @post = Post.new(post_params)

    if @post.save
      redirect_to polymorphic_path(@post)
    else
      render :index
    end
  end

  private

  def post_params
    params.require(:post).permit(:type, :title, :content).tap do |p|
      p.delete(:title) unless p[:type] == "Article"
    end
  end
end
