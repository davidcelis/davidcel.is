class ApplicationController < ActionController::Base
  include Pagy::Backend

  def authenticated?
    cookies.encrypted[:github_user_id] == Rails.application.credentials.dig(:github, :user_id)
  end
  helper_method :authenticated?

  def require_authentication
    redirect_to root_path unless authenticated?
  end

  def link_preview_requested?
    request.env["HTTP_USER_AGENT"].match?(%r{facebookexternalhit/1.1 Facebot Twitterbot/1.0\z})
  end
  helper_method :link_preview_requested?
end
