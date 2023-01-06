class ApplicationController < ActionController::Base
  include Pagy::Backend

  def authenticated?
    cookies.encrypted[:github_user_id] == Rails.application.credentials.dig(:github, :user_id)
  end
  helper_method :authenticated?
end
