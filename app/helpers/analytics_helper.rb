module AnalyticsHelper
  def track_page_view
    plausible_client.event(
      name: "pageview",
      domain: plausible_domain,
      url: request.original_url,
      user_agent: request.user_agent,
      referrer: request.referrer,
      ip: request.remote_ip
    )
  rescue => e
    # Don't let Plausible errors break the app, but let me know
    Sentry.capture_exception(e)
  end

  private

  def plausible_client
    @client ||= if Rails.env.production?
      PlausibleApi::Client.new(plausible_domain, plausible_api_key)
    else
      NullClient.new
    end
  end

  def plausible_domain
    @plausible_domain ||= Rails.application.credentials.dig(:plausible, :site_id)
  end

  def plausible_api_key
    @plausible_api_key ||= Rails.application.credentials.dig(:plausible, :api_key)
  end

  class NullClient
    def event(*)
    end
  end
end
