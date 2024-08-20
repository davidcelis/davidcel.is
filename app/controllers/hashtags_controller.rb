class HashtagsController < ApplicationController
  def show
    posts = Post
      .includes(Post::DEFAULT_INCLUDES)
      .where("hashtags @> ARRAY[?]::varchar[]", params[:id].downcase)
    posts = posts.unscope(:order).search(params[:q]) if params[:q].present?
    @pagy, @posts = pagy(posts)

    ActiveRecord::Precounter.new(@posts).precount(:likes, :reposts, :replies)

    # For check-ins, we'll preload their associated places.
    ActiveRecord::Associations::Preloader.new(
      records: @posts.select(&:check_in?),
      associations: CheckIn::DEFAULT_INCLUDES
    ).call

    # For link previews, we'll preload their favicons and preview images.
    ActiveRecord::Associations::Preloader.new(
      records: @posts.select(&:link?),
      associations: Link::DEFAULT_INCLUDES
    ).call

    render "posts/index", formats: [:html]
  end
end
