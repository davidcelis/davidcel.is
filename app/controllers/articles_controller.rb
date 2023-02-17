class ArticlesController < ApplicationController
  def index
    @pagy, @posts = pagy(Article.includes(Post::DEFAULT_INCLUDES))

    render "posts/index"
  end

  def show
    @article = Article.find_by!(slug: params[:id])
  end
end
