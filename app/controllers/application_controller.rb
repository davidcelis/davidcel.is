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
end
