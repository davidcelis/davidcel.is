class Avo::Resources::Article < Avo::BaseResource
  self.link_to_child_resource = true

  self.title = :title

  self.find_record_method = -> do
    if id.is_a?(Array)
      (id.first.to_i == 0) ? query.where(slug: id) : query.where(id: id)
    else
      (id.to_i == 0) ? query.find_by_slug(id) : query.find(id)
    end
  end

  self.includes = Post::DEFAULT_INCLUDES
  # self.search_query = -> do
  #   scope.ransack(id_eq: params[:q], m: "or").result(distinct: false)
  # end

  def fields
    field :id, as: :id

    field :title, as: :text
    field :slug, as: :text, readonly: true, hide_on: [:index]
    field :content, as: :code, language: "markdown", theme: "dracula", hide_on: [:index]
  end
end
