class Avo::Resources::MediaAttachment < Avo::BaseResource
  self.title = :id
  self.description = -> do
    if view.in?(%i[show edit])
      model.post.content
    else
      "Photos, videos, and other media attachments"
    end
  end

  self.includes = MediaAttachment::DEFAULT_INCLUDES
  self.index_query = -> { query.unscoped }
  self.default_view_type = :grid
  self.after_update_path = :index

  # self.search_query = -> do
  #   scope.ransack(id_eq: params[:q], m: "or").result(distinct: false)
  # end

  self.grid_view = {
    card: -> do
      {
        cover_url: Rails.application.routes.url_helpers.cdn_file_url(record),
        title: record.post.title.presence || record.post.content.presence || record.post.id,
        body: record.description
      }
    end
  }

  def filters
    filter Avo::Filters::HasAltText
    filter Avo::Filters::IsFeatured
  end

  def actions
    action Avo::Actions::ToggleFeatured
  end

  def fields
    field :id, as: :id
    field :description, as: :textarea
    field :file, as: :file
    field :featured, as: :boolean
  end
end
