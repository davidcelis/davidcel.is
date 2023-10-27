class ArticlesController < ApplicationController
  def index
    articles = Article.includes(Post::DEFAULT_INCLUDES)
    articles = articles.unscope(:order).search(params[:q]) if params[:q].present?
    @pagy, @posts = pagy(articles)

    render "posts/index", formats: [:html]
  end

  def show
    @article = Article.includes(Post::DEFAULT_INCLUDES).find_by!(slug: params[:id])

    respond_to :html
  end
end
