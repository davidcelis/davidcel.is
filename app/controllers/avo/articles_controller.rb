# This controller has been generated to enable Rails' resource routes.
# More information on https://docs.avohq.io/2.0/controllers.html
class Avo::ArticlesController < Avo::ResourcesController
  def set_model
    @model = eager_load_files(@resource, @resource.class.find_scope).find_by slug: params[:id]
  end
end
