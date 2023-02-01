class MediaAttachmentResource < Avo::BaseResource
  self.title = :id
  self.description = -> do
    if view.in?(%i[show edit])
      model.post.content
    else
      "Photos, videos, and other media attachments"
    end
  end

  self.includes = [:post, {file_attachment: :blob, preview_image_attachment: :blob}]
  self.default_view_type = :grid
  self.after_update_path = :index

  # self.search_query = -> do
  #   scope.ransack(id_eq: params[:q], m: "or").result(distinct: false)
  # end

  grid do
    cover :file, as: :external_image, link_to_resource: true do |media|
      image = media.preview_image.attached? ? media.preview_image : media.file

      Rails.application.routes.url_helpers.cdn_file_url(image)
    end

    title :title, as: :text, required: true, link_to_resource: true do |media|
      case media.post
      when Note
        media.post.content || media.post.id
      when Article
        media.post.title
      end
    end

    body :description, as: :text
  end

  filter HasAltTextFilter

  field :id, as: :id

  # Fields generated from the model
  field :description, as: :textarea
  field :file, as: :file

  # Add more fields here
end
