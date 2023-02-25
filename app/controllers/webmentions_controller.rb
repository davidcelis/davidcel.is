class WebmentionsController < ApplicationController
  before_action :verify_webmention

  def receive
    Webmention.find_or_create_by!(params.slice(:source, :target))

    head :accepted
  end
end
