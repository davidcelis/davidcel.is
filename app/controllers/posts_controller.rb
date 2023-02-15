class PostsController < ApplicationController
  before_action :require_authentication, only: [:create]

  def index
    @pagy, @posts = pagy(Post.includes(Post::DEFAULT_INCLUDES))
    @posts = Post.filter_posts_with_unprocessed_media(@posts)
  end

  def show
    @post = Post.find(params[:id])

    instance_variable_set("@#{@post.type.underscore}", @post)

    render "#{@post.type.tableize}/show"
  end

  def create
    @post = Post.new(post_params)

    ActiveRecord::Base.transaction do
      Array(params[:post][:media_attachments]).each_with_index do |file, i|
        media_attachment = @post.media_attachments.new(
          id: ActiveRecord::Base.connection.select_value("SELECT public.snowflake_id();"),
          description: params[:post][:media_attachment_descriptions][i].strip.presence
        )

        # If the file is a GIF, convert it to a webm file to save on space, while
        # preserving the fact that it was a GIF and is meant to play like a gif.
        original_content_type = file.content_type
        if original_content_type == "image/gif"
          webm = ActionDispatch::Http::UploadedFile.new(tempfile: Tempfile.open([file.original_filename, ".webm"]), type: "video/webm")

          ffmpeg = ActiveStorage::Previewer::VideoPreviewer.ffmpeg_path
          system(ffmpeg, "-y", "-i", file.path, "-movflags", "faststart", "-pix_fmt", "yuv420p", "-vf", "scale=trunc(iw/2)*2:trunc(ih/2)*2", webm.path, exception: true)
          file = webm
        end

        file_extension = Rack::Mime::MIME_TYPES.invert[file.content_type]
        filename = "#{media_attachment.id}#{file_extension}"

        media_attachment.file.attach(
          key: "blog/#{filename}",
          io: file.to_io,
          filename: filename,
          metadata: {custom: {original_content_type: original_content_type}}
        )

        media_attachment.save!
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
end
