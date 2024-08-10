class FeedsController < ApplicationController
  before_action :set_proper_content_type, except: :index
  after_action :track_page_view

  def index
  end

  def main
    _, @posts = pagy(Post.main.includes(Post::FEED_INCLUDES))

    # For check-ins, we'll preload their places and snapshots
    ActiveRecord::Associations::Preloader.new(
      records: @posts.select(&:check_in?),
      associations: CheckIn::DEFAULT_INCLUDES + [{snapshot_attachment: :blob}]
    ).call

    @self_url = main_feed_url
    @alternate_url = root_url

    render :feed, formats: :xml
  end

  def all
    _, @posts = pagy(Post.includes(Post::FEED_INCLUDES))

    # For check-ins, we'll preload their places and snapshots
    ActiveRecord::Associations::Preloader.new(
      records: @posts.select(&:check_in?),
      associations: CheckIn::DEFAULT_INCLUDES + [{snapshot_attachment: :blob}]
    ).call

    @subtitle = "Everything"
    @self_url = all_feed_url
    @alternate_url = root_url

    render :feed, formats: :xml
  end

  def articles
    _, @posts = pagy(Article.includes(Post::FEED_INCLUDES))

    @subtitle = "Articles"
    @self_url = articles_feed_url
    @alternate_url = articles_url

    render :feed, formats: :xml
  end

  def check_ins
    _, @posts = pagy(Post::FEED_INCLUDES + CheckIn::DEFAULT_INCLUDES + [{snapshot_attachment: :blob}])

    @subtitle = "Check-ins"
    @self_url = check_ins_feed_url
    @alternate_url = check_ins_url

    render :feed, formats: :xml
  end

  def links
    _, @posts = pagy(Link.includes(Post::FEED_INCLUDES))

    @subtitle = "Links"
    @self_url = links_feed_url
    @alternate_url = links_url

    render :feed, formats: :xml
  end

  def notes
    _, @posts = pagy(Note.includes(Post::FEED_INCLUDES))

    @subtitle = "Notes"
    @self_url = notes_feed_url
    @alternate_url = notes_url

    render :feed, formats: :xml
  end

  def photos
    posts = Post.includes(Post::FEED_INCLUDES)
      .joins(:media_attachments)
      .where(media_attachments: {featured: true})

    _, @posts = pagy(posts)

    @subtitle = "Photos"
    @self_url = photos_feed_url
    @alternate_url = photos_url

    render :feed, formats: :xml
  end

  private

  def set_proper_content_type
    response.headers.delete "X-Content-Type-Options"
    response.headers["Content-Type"] = "text/xml; charset=utf-8"
  end
end
