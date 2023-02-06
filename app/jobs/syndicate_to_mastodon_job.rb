class SyndicateToMastodonJob < ApplicationJob
  include Rails.application.routes.url_helpers

  def perform(post_id)
    post = Post.find(post_id)

    content = case post
    when Note
      post.content
    when Article
      "“#{post.title}”\n\n#{article_url(post)}"
    end

    status = client.create_status(content: content, idempotency_key: post.id)

    post.syndication_links.create!(
      platform: "mastodon",
      url: status["url"]
    )
  end

  private

  def client
    @client ||= Mastodon::Client.new
  end
end
