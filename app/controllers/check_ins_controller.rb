class CheckInsController < ApplicationController
  def index
    check_ins = CheckIn.includes(Post::DEFAULT_INCLUDES + CheckIn::DEFAULT_INCLUDES)
    check_ins = check_ins.search(params[:q]) if params[:q].present?

    @pagy, @posts = pagy(check_ins)

    ActiveRecord::Precounter.new(@posts).precount(:likes, :reposts, :replies)

    respond_to :html
  end

  def show
    @check_in = CheckIn.includes(Post::DEFAULT_INCLUDES).find_by!(slug: params[:id])

    respond_to :html
  end
end
