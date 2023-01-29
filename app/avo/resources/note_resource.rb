class NoteResource < Avo::BaseResource
  self.link_to_child_resource = true

  self.title = :id

  self.includes = [{media_attachments: {file_attachment: :blob}}]
  # self.search_query = -> do
  #   scope.ransack(id_eq: params[:q], m: "or").result(distinct: false)
  # end

  field :id, as: :id

  # Fields generated from the model
  field :slug, as: :text, readonly: true
  field :content, as: :code, language: "markdown", theme: "dracula", hide_on: [:index]

  # Add more fields here
end
