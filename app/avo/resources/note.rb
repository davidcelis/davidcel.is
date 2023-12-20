class Avo::Resources::Note < Avo::BaseResource
  self.link_to_child_resource = true

  self.title = :id

  self.includes = Post::DEFAULT_INCLUDES
  # self.search_query = -> do
  #   scope.ransack(id_eq: params[:q], m: "or").result(distinct: false)
  # end

  def fields
    field :id, as: :id
    field :slug, as: :text, readonly: true
    field :content, as: :code, language: "markdown", theme: "dracula", hide_on: [:index]
  end
end
