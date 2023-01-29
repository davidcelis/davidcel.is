class PostsController < ApplicationController
  def index
    @pagy, @posts = pagy(Post.includes(media_attachments: {file_attachment: :blob, preview_image_attachment: :blob}))
  end

  def show
    @post = Post.find(params[:id])

    instance_variable_set("@#{@post.type.underscore}", @post)

    render "#{@post.type.tableize}/show"
  end
end
