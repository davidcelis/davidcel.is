class ArticlesController < ApplicationController
  def index
    @pagy, @posts = pagy(Article.all)

    render "posts/index"
  end

  def show
    @article = Article.find_by!(slug: params[:id])
  end
end
