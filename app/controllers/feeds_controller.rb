class FeedsController < ApplicationController
  before_action :set_proper_content_type

  def main
    _, @posts = pagy(Post.all)

    @self_url = main_feed_url
    @alternate_url = root_url

    render :feed, formats: :xml
  end

  def articles
    _, @posts = pagy(Article.all)

    @subtitle = "Articles"
    @self_url = articles_feed_url
    @alternate_url = articles_url

    render :feed, formats: :xml
  end

  def notes
    _, @posts = pagy(Note.all)

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
