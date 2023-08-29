class CheckInsController < ApplicationController
  def index
    @pagy, @posts = pagy(CheckIn.includes(Post::DEFAULT_INCLUDES))

    render "posts/index"
  end

  def show
    @check_in = CheckIn.find_by!(slug: params[:slug])
  end
end
