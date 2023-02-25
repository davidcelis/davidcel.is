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

    # Extract the microformats2
    mf2 = Microformats.parse(webmention.html)

    # Update the webmention
    webmention.mf2 = mf2.to_hash

    # Mark the webmention as verified
    webmention.verified!
  end
end
