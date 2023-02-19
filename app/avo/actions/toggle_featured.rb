class ToggleFeatured < Avo::BaseAction
  self.name = "Toggle featured"

  def handle(**args)
    models = args[:models]

    # If every selection shares the same value, toggle them. Otherwise, mark
    # them all as featured.
    if models.all?(&:featured?) || models.none?(&:featured?)
      models.each { |model| model.update!(featured: !model.featured) }
    else
      models.each { |model| model.update!(featured: true) }
    end

    succeed "Done."
  end
end
