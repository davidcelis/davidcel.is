class ArticlesController < ApplicationController
  def index
    articles = Article.includes(Post::DEFAULT_INCLUDES)
    articles = articles.search(params[:q]) if params[:q].present?
    @pagy, @posts = pagy(articles)

    render "posts/index"
  end

  def show
    @article = Article.find_by!(slug: params[:id])
  end
end
