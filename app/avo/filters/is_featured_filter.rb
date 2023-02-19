class IsFeaturedFilter < Avo::Filters::BooleanFilter
  self.name = "Featured?"

  # self.visible = -> do
  #   true
  # end

  def apply(request, query, values)
    return query if values["yes"] && values["no"]

    if values["yes"]
      query = query.where(featured: true)
    elsif values["no"]
      query = query.where(featured: false)
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
    {}
  end
end
