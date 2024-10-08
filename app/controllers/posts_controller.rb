class PostsController < ApplicationController
  before_action :require_authentication, only: [:create, :edit, :update]

  def index
    posts = Post.includes(Post::DEFAULT_INCLUDES)
    posts = posts.unscope(:order).search(params[:q]) if params[:q].present?
    @pagy, @posts = pagy(posts)

    ActiveRecord::Precounter.new(@posts).precount(:likes, :reposts, :replies)

    # For check-ins, we'll preload their associated places.
    ActiveRecord::Associations::Preloader.new(
      records: @posts.select(&:check_in?),
      associations: CheckIn::DEFAULT_INCLUDES
    ).call

    # For link previews, we'll preload their favicons and preview images.
    ActiveRecord::Associations::Preloader.new(
      records: @posts.select(&:link?),
      associations: Link::DEFAULT_INCLUDES
    ).call

    respond_to :html
  end

  def show
    @post = Post.includes(Post::DEFAULT_INCLUDES).find(params[:id])

    instance_variable_set(:"@#{@post.type.underscore}", @post)

    render "#{@post.type.tableize}/show", formats: [:html]
  end

  def create
    # If the post is being created with any media attachments, we'll push the
    # post creation into a background job. This lets us handle the processing
    # of the media attachments without hogging a web worker and also ensures
    # we can wait to create the Post object until the media is done processing.
    # This includes check-ins (they generate an Apple Maps snapshot) as well as
    # links (they store cached versions of the link's relevant images like open
    # graph images and a favicons).
    if media_attachments_params.any? || place_params.key?(:apple_maps_id) || post_params[:type] == "Link"
      CreatePostWithMediaJob.perform_async(post_params.to_hash, media_attachments_params.map(&:to_hash), place_params.to_hash)

      redirect_to root_path, notice: "Your post’s media is being processed and will be available shortly."
      return
    end

    @post = Post.new(post_params)

    # Use the WeatherKit API to get the weather for the post's location.
    begin
      aqi = AQI.at(latitude: @post.latitude, longitude: @post.longitude)
      @post.weather = {"airQualityIndex" => aqi}

      response = Apple::WeatherKit::CurrentWeather.at(latitude: @post.latitude, longitude: @post.longitude)
      @post.weather.merge!(response["currentWeather"])
    rescue Faraday::Error
      # Occasionally, Apple's WeatherKit API just starts returning 401s for no
      # reason. These have always been transient, but it typically takes a few
      # hours before resolving itself. To avoid preventing myself from posting
      # for long stretches of time, I just enqueue a job to bring the weather
      # data in later, and the job can retry until it works.
    end

    # If we don't have a check-in, we'll still find or create a generic Place
    # for the post's location.
    @post.place = Place.find_or_create_by(place_params) if place_params.present?

    if @post.save
      AddWeatherToPostJob.perform_async(@post.id) unless @post.has_weather_data?

      redirect_to polymorphic_path(@post)
    else
      render :index, alert: @post.errors.full_messages.to_sentence
    end
  end

  def edit
    @post = Post.includes(Post::DEFAULT_INCLUDES).find(params[:id])
  end

  def update
    post = Post.find(params[:id])

    ActiveRecord::Base.transaction do
      # We only support updating the post's title, content, and media
      post_params = params.require(:post).permit(:title, :content)
      post.update!(post_params)

      # Destroy any media attachments that weren't re-submitted in the update
      post.media_attachments.where.not(id: media_attachments_params.map { |p| p[:id] }).destroy_all

      # Update or create the media attachments that _were_ submitted
      media_attachments_params.each do |media_attachment_params|
        media_attachment = if media_attachment_params[:id].present?
          post.media_attachments.find(media_attachment_params[:id])
        elsif media_attachment_params[:signed_id].present?
          post.media_attachments.new(file: media_attachment_params[:signed_id])
        end

        media_attachment.update!(media_attachment_params.slice(:description, :featured))
      end
    end

    redirect_to polymorphic_path(post), notice: "Post updated!"
  end

  def destroy
    post = Post.find(params[:id])
    post.destroy!

    redirect_to root_path, notice: "Post deleted!"
  end

  private

  def post_params
    params.require(:post).permit(:type, :title, :content, :latitude, :longitude, :link_data).tap do |p|
      p.delete(:title) unless %(Article Link).include?(p[:type])

      p[:link_data] = JSON.parse(p[:link_data]) if p[:type] == "Link"
    end
  end

  def media_attachments_params
    params.require(:post).permit(media_attachments: [:id, :signed_id, :description, :featured]).fetch(:media_attachments, [])
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
