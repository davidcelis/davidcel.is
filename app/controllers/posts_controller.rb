class PostsController < ApplicationController
  before_action :require_authentication, only: [:create]

  def index
    posts = Post.includes(Post::DEFAULT_INCLUDES)
    posts = posts.search(params[:q]) if params[:q].present?
    @pagy, @posts = pagy(posts)
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
    # This includes _all_ check-ins, since they generate an Apple Maps snapshot.
    if media_attachments_params.any? || place_params.key?(:apple_maps_id)
      CreatePostWithMediaJob.perform_async(post_params.to_hash, media_attachments_params.map(&:to_hash), place_params.to_hash)

      redirect_to root_path, notice: "Your post’s media is being processed and will be available shortly."
      return
    end

    @post = Post.new(post_params)

    # Use the WeatherKit API to get the weather for the post's location.
    Sentry.configure_scope do |scope|
      scope.set_context("params", params.to_unsafe_h)

      if @post.latitude && @post.longitude
        response = Apple::WeatherKit::CurrentWeather.at(latitude: @post.latitude, longitude: @post.longitude)
        @post.weather = response["currentWeather"]
      else
        Sentry.capture_message("No coordinates")
      end
    end

    # If we don't have a check-in, we'll still find or create a generic Place
    # for the post's location.
    @post.place = Place.find_or_create_by(place_params) if place_params.present?

    if @post.save
      redirect_to polymorphic_path(@post)
    else
      render :index, alert: @post.errors.full_messages.to_sentence
    end
  end

  private

  def post_params
    params.require(:post).permit(:type, :title, :content, :latitude, :longitude).tap do |p|
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
    ]).fetch(:place, {}).compact_blank
  end
end
