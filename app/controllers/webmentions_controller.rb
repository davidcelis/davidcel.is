class WebmentionsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def receive
    webmention = Webmention.find_or_create_by!(webmention_params)

    ProcessWebmentionJob.perform_async(webmention.id)

    if params[:manual]
      redirect_to params[:target], notice: "Thanks for letting me know! Your webmention will be processed shortly."
    else
      head :accepted
    end
  end

  private

  def webmention_params
    params.permit(:source, :target)
  end
end
