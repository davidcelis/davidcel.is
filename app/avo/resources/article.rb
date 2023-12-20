class Avo::Resources::Article < Avo::BaseResource
  self.link_to_child_resource = true

  self.title = :title

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
