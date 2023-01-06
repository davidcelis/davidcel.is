class ArticleResource < Avo::BaseResource
  self.link_to_child_resource = true

  self.title = :title

  self.includes = []
  # self.search_query = -> do
  #   scope.ransack(id_eq: params[:q], m: "or").result(distinct: false)
  # end

  field :id, as: :id

  # Fields generated from the model
  field :title, as: :text
  field :slug, as: :text, readonly: true, hide_on: [:index]
  field :content, as: :code, language: "markdown", theme: "dracula"

  # Add more fields here
end
