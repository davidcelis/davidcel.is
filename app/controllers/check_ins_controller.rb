class CheckInsController < ApplicationController
  def index
    check_ins = CheckIn.includes(Post::DEFAULT_INCLUDES)
    check_ins = check_ins.search(params[:q]) if params[:q].present?

    @pagy, @posts = pagy(check_ins)

    ActiveRecord::Precounter.new(@posts).precount(:likes, :reposts, :replies)

    render "posts/index", formats: [:html]
  end

  def show
    @check_in = CheckIn.includes([
      {snapshot_attachment: :blob},
      {webp_snapshot_attachment: :blob},
      *Post::DEFAULT_INCLUDES
    ]).find_by!(slug: params[:id])

    respond_to :html
  end
end
