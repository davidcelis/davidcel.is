class ApplicationController < ActionController::Base
  include Pagy::Backend

  # All HTML responses will be served with Plausible's script; for other requests,
  # we'll manually send an event to Plausible.
  after_action :track_page_view, unless: -> { request.format.html? }

  rescue_from Pagy::VariableError do |e|
    @exception = Errors::BadRequest.new(e.message, original_exception: e)

    render "errors/bad_request", status: @exception.status_code
  end

  def authenticated?
    cookies.encrypted[:github_user_id] == Rails.application.credentials.dig(:github, :user_id)
  end
  helper_method :authenticated?

  def require_authentication
    redirect_to root_path unless authenticated?
  end

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
  helper_method :track_page_view

  private

  def plausible_client
    @client ||= if Rails.env.production?
      PlausibleApi::Client.new(plausible_domain, plausible_api_key)
    else
      NullPlausibleClient.new
    end
  end

  def plausible_domain
    @plausible_domain ||= Rails.application.credentials.dig(:plausible, :site_id)
  end

  def plausible_api_key
    @plausible_api_key ||= Rails.application.credentials.dig(:plausible, :api_key)
  end

  class NullPlausibleClient
    def event(*)
    end
  end
end
