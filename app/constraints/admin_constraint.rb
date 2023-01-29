class AdminConstraint
  def matches?(request)
    cookies = ActionDispatch::Cookies::CookieJar.build(request, request.cookies)

    cookies.encrypted[:github_user_id] == Rails.application.credentials.dig(:github, :user_id)
  end
end
