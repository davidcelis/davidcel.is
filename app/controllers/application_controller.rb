class ApplicationController < ActionController::Base
  include Pagy::Backend

  def current_user
    @current_user ||= if cookies.encrypted[:github_user_id].present?
      User.new(id: cookies.encrypted[:github_user_id], username: cookies.encrypted[:github_username])
    end
  end
  helper_method :current_user

  def authenticated?
    current_user.present?
  end
  helper_method :authenticated?
end
