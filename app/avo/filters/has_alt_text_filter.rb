class HasAltTextFilter < Avo::Filters::BooleanFilter
  self.name = "Has alt text?"

  # self.visible = -> do
  #   true
  # end

  def apply(request, query, values)
    return query if values["yes"] && values["no"]

    if values["yes"]
      query = query.where.not(description: nil)
    elsif values["no"]
      query = query.where(description: nil)
    end

    query
  end

  def options
    {
      yes: "Yes",
      no: "No"
    }
  end

  def default
    {
      no: true
    }
  end
end
