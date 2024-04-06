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
  rescue ActiveRecord::RecordInvalid => e
    if params[:manual]
      redirect_to params[:target], alert: "Oops, it looks like you tried to enter something that wasn't a URL. Webmentions must be a valid URL."
    else
      render json: {error: e.message}, status: :unprocessable_entity
    end
  end

  private

  def webmention_params
    params.permit(:source, :target)
  end
end
