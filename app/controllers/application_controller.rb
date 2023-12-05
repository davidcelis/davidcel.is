class ApplicationController < ActionController::Base
  include Pagy::Backend

  rescue_from Pagy::VariableError do |e|
    raise Errors::BadRequest.new(e.message, original_exception: e)
  end

  def authenticated?
    cookies.encrypted[:github_user_id] == Rails.application.credentials.dig(:github, :user_id)
  end
  helper_method :authenticated?

  def require_authentication
    redirect_to root_path unless authenticated?
  end
end
