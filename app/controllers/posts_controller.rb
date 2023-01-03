class PostsController < ApplicationController
  def index
    @pagy, @posts = pagy(Post.all)
  end

  def show
    @post = Post.find(params[:id])

    instance_variable_set("@#{@post.type.underscore}", @post)

    render "#{@post.type.tableize}/show"
  end

  def feed
    _, @posts = pagy(Post.all)

    @subtitle = "All Posts"

    response.headers.delete "X-Content-Type-Options"

    render formats: :xml, content_type: "text/xml; charset=utf-8"
  end
end
