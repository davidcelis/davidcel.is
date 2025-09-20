class ProcessWebmentionJob < ApplicationJob
  def perform(webmention_id)
    webmention = Webmention.find(webmention_id)

    # Associate the webmention with a post, if any
    webmention.post = find_post(webmention.target)

    # Fetch and cache the source page
    response = Faraday.get(webmention.source)
    return webmention.failed! unless response.success?

    # Save the webmention's HTML and extract its microformats2
    webmention.html = response.body
    mf2 = Microformats.parse(webmention.html, base: URI.join(webmention.source, "/").to_s)
    webmention.mf2 = mf2.to_hash

    # For convenience, set the type of the webmention based on the microformats
    h_entry = mf2.items.find { |item| item.type == "h-entry" }
    webmention.type = case
    when h_entry.respond_to?(:like_of)
      "like"
    when h_entry.respond_to?(:repost_of)
      "repost"
    when h_entry.respond_to?(:in_reply_to)
      "reply"
    else
      "mention"
    end

    # Next, verify that the source page contains a link to the target. The
    # sole exception is if the webmention came from brid.gy, which fails to
    # include the target URL in its source under certain unknown conditions.
    if URI.parse(webmention.source).host != "brid.gy"
      mentioned_urls = URI.extract(webmention.html, %w[http https])
      return webmention.failed! unless mentioned_urls.include?(webmention.target)
    end

    # Depending on the webmention and where it came from, we might have a reply
    # with no content. If that happened, mark it as failed and bail.
    if webmention.type == "reply" && !h_entry.respond_to?(:content)
      return webmention.failed!
    end

    # Otherwise, mark the webmention as verified!
    webmention.verified!
  end

  private

  def find_post(target)
    route = Rails.application.routes.recognize_path(target)
    return unless route[:action] == "show"

    model = route[:controller].classify.constantize
    if model == Article
      model.find_by(slug: route[:id])
    else
      model.find(route[:id])
    end
  rescue ActionController::RoutingError, ActiveRecord::RecordNotFound
    nil
  end
end
