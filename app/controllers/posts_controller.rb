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
    # If the post is being created with any media attachments, we'll push the
    # post creation into a background job. This lets us handle the processing
    # of the media attachments without hogging a web worker and also ensures
    # we can wait to create the Post object until the media is done processing.
    if media_attachments_params.any?
      CreatePostWithMediaJob.perform_async(post_params.to_hash, media_attachments_params.map(&:to_hash), place_params.to_hash)

      redirect_to root_path, notice: "Your post's media is being processed and will be available shortly."
      return
    end

    @post = Post.new(post_params)

    ActiveRecord::Base.transaction do
      if place_params.any?
        place = Place.find_or_initialize_by(apple_maps_id: place_params[:apple_maps_id])
        place.update!(place_params)

        @post.type = "CheckIn"
        @post.place = place
      end

      @post.save!
    end

    if @post.persisted?
      redirect_to polymorphic_path(@post)
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

  def place_params
    params.require(:post).permit(place: %i[
      name
      category
      street
      city
      state
      state_code
      postal_code
      country
      country_code
      latitude
      longitude
      apple_maps_id
      apple_maps_url
    ]).fetch(:place, {})
  end
end
