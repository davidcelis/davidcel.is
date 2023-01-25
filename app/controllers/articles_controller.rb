class ArticlesController < ApplicationController
  def index
    @pagy, @posts = pagy(Article.includes(media_attachments: {file_attachment: :blob}))

    render "posts/index"
  end

  def show
    @article = Article.find_by!(slug: params[:id])
  end
end
