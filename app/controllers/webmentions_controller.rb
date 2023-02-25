class WebmentionsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def receive
    webmention = Webmention.find_or_create_by!(webmention_params)

    ProcessWebmentionJob.perform_later(webmention.id)

    head :accepted
  end

  private

  def webmention_params
    params.permit(:source, :target)
  end
end
