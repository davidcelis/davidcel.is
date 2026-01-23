class LinksController < ApplicationController
  def index
    links = Link.includes(Post::DEFAULT_INCLUDES + Link::DEFAULT_INCLUDES)
    links = links.unscope(:order).search(params[:q]) if params[:q].present?
    @pagy, @posts = pagy(links)

    ActiveRecord::Precounter.new(@posts).precount(:likes, :reposts, :replies)

    respond_to :html
  end

  def show
    @link = Link.includes(Post::DEFAULT_INCLUDES).find_by!(slug: params[:id])

    respond_to :html
  end
end
