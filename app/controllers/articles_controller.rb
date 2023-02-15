class ArticlesController < ApplicationController
  def index
    @pagy, @posts = pagy(Article.includes(Post::DEFAULT_INCLUDES))
    @posts = Post.filter_posts_with_unprocessed_media(@posts)

    render "posts/index"
  end

  def show
    @article = Article.find_by!(slug: params[:id])
  end
end
