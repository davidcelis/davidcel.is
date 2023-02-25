class ProcessWebmentionJob < ApplicationJob
  def perform(webmention_id)
    webmention = Webmention.find(webmention_id)

    # Fetch and cache the source page
    response = HTTParty.get(webmention.source)
    return webmention.failed! unless response.success?

    webmention.html = response.body

    # Verify that the source page contains a link to the target
    mentioned_urls = URI.extract(webmention.html, %w[http https])
    return webmention.failed! unless mentioned_urls.include?(webmention.target)

    # Associate the webmention with a post, if any
    webmention.post = find_post(webmention.target)

    # Extract the microformats2
    mf2 = Microformats.parse(webmention.html, base: URI.join(webmention.source, "/").to_s)

    # Update the webmention
    webmention.mf2 = mf2.to_hash

    # Mark the webmention as verified
    webmention.verified!
  end

  private

  def find_post(target)
    route = Rails.application.routes.recognize_path(target)
    return unless route[:action] == "show"

    model = route[:controller].classify.constantize
    model.find(route[:id])
  rescue ActionController::RoutingError, ActiveRecord::RecordNotFound
    nil
  end
end
