class FeedsController < ApplicationController
  before_action :set_proper_content_type

  def main
    _, @posts = pagy(Post.main.includes(Post::DEFAULT_INCLUDES))

    @self_url = main_feed_url
    @alternate_url = root_url

    render :feed, formats: :xml
  end

  def all
    _, @posts = pagy(Post.includes(Post::DEFAULT_INCLUDES))

    @subtitle = "Everything"
    @self_url = all_feed_url
    @alternate_url = root_url

    render :feed, formats: :xml
  end

  def articles
    _, @posts = pagy(Article.includes(Post::DEFAULT_INCLUDES))

    @subtitle = "Articles"
    @self_url = articles_feed_url
    @alternate_url = articles_url

    render :feed, formats: :xml
  end

  def check_ins
    _, @posts = pagy(CheckIn.includes(Post::DEFAULT_INCLUDES))

    @subtitle = "Check-ins"
    @self_url = check_ins_feed_url
    @alternate_url = check_ins_url

    render :feed, formats: :xml
  end

  def links
    _, @posts = pagy(Link.includes(Post::DEFAULT_INCLUDES + Link::DEFAULT_INCLUDES))

    @subtitle = "Links"
    @self_url = links_feed_url
    @alternate_url = links_url

    render :feed, formats: :xml
  end

  def notes
    _, @posts = pagy(Note.includes(Post::DEFAULT_INCLUDES))

    @subtitle = "Notes"
    @self_url = notes_feed_url
    @alternate_url = notes_url

    render :feed, formats: :xml
  end

  private

  def set_proper_content_type
    response.headers.delete "X-Content-Type-Options"
    response.headers["Content-Type"] = "text/xml; charset=utf-8"
  end
end
