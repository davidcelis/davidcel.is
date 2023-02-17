class PostsController < ApplicationController
  before_action :require_authentication, only: [:create]

  def index
    @pagy, @posts = pagy(Post.includes(Post::DEFAULT_INCLUDES))
  end

  def show
    @post = Post.find(params[:id])

    instance_variable_set("@#{@post.type.underscore}", @post)

    render "#{@post.type.tableize}/show"
  end

  def create
    @post = Post.new(post_params)

    ActiveRecord::Base.transaction do
      media_attachments_params.each do |blob|
        media_attachment = @post.media_attachments.new(
          file: blob[:signed_id],
          description: blob.fetch(:description, "").strip.presence
        )

        # If the post is being created with any video attachments, which need to
        # have a preview image generated, or a GIF, which needs to be converted
        # to a video, we'll push the post creation into a background job. This
        # lets us handle the processing of the media attachments without hogging
        # a web worker and also ensures we can wait to create the Post object
        # until the media is done processing.
        if media_attachment.file.video? || media_attachment.file.content_type == "image/gif"
          CreatePostWithMediaJob.perform_async(post_params.to_h, media_attachments_params.map(&:to_h))

          @post_will_be_created_later = true
          raise ActiveRecord::Rollback
        end

        media_attachment.save!
      end

      @post.save!
    end

    if @post.persisted?
      redirect_to polymorphic_path(@post)
    elsif @post_will_be_created_later
      redirect_to root_path, notice: "Your post's media is being processed and will be available shortly."
    else
      render :index, alert: @post.errors.full_messages.to_sentence
    end
  end

  private

  def post_params
    params.require(:post).permit(:type, :title, :content).tap do |p|
      p.delete(:title) unless p[:type] == "Article"
    end
  end

  def media_attachments_params
    params.require(:post).permit(media_attachments: [:signed_id, :description]).fetch(:media_attachments, [])
  end
end
