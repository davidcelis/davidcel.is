class CheckInsController < ApplicationController
  def index
    check_ins = CheckIn.includes(Post::DEFAULT_INCLUDES)
    check_ins = check_ins.search(params[:q]) if params[:q].present?

    @pagy, @posts = pagy(check_ins)

    render "posts/index"
  end

  def show
    @check_in = CheckIn.find_by!(slug: params[:id])
  end
end
