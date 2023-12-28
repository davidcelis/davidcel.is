class Avo::Actions::ToggleFeatured < Avo::BaseAction
  self.name = "Toggle featured"

  def handle(**args)
    records = args[:query]

    # If every selection shares the same value, toggle them. Otherwise, mark
    # them all as featured.
    if records.all?(&:featured?) || records.none?(&:featured?)
      records.each { |record| record.update!(featured: !record.featured) }
    else
      records.each { |record| record.update!(featured: true) }
    end

    succeed "Done."
  end
end
