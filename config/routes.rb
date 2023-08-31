require "sidekiq/web"

Rails.application.routes.draw do
  root to: "posts#index"

  get "/about", to: "pages#about"

  resources :posts, only: [:index, :create]
  resources :articles, only: [:index, :show]
  resources :check_ins, only: [:index, :show], path: "check-ins"
  resources :notes, only: [:index, :show]
  resources :photos, only: [:index]

  get "/feeds/main", to: "feeds#main", format: :xml, as: :main_feed
  get "/feeds/articles", to: "feeds#articles", format: :xml, as: :articles_feed
  get "/feeds/notes", to: "feeds#notes", format: :xml, as: :notes_feed
  get "/feed", to: "feeds#main", format: :xml

  # For the generic /posts/:id route (i.e. to route to a post without using
  # its type, like Article or Note), we'll only support numeric IDs. Only
  # polymorphic routes will support something like fetching posts by slugs.
  # This also ensures that our legacy URLs listed below won't conflict.
  get "/posts/:id", to: "posts#show", as: :post, constraints: {id: /\d+/}

  post :webmention, to: "webmentions#receive"

  # Set up routes for me to authenticate and write/edit posts.
  namespace :github do
    namespace :oauth do
      get :callback
    end
  end

  # Route media attachments through a CDN.
  direct :cdn_file do |file|
    if Rails.configuration.cdn_host.present?
      File.join(Rails.configuration.cdn_host, file.key)
    else
      route_for(:rails_blob, file)
    end
  end

  post :direct_uploads, to: "direct_uploads#create", as: :direct_uploads

  constraints(AdminConstraint.new) do
    mount Avo::Engine, at: Avo.configuration.root_path
    mount Sidekiq::Web => "/admin/sidekiq"
  end

  get :sign_in, to: "sessions#new"
  delete :sign_out, to: "sessions#destroy"

  # Finally, ensure old URLs redirect to the new location for existing articles
  get "/blog/2012/02/01/why-i-hate-five-star-ratings", to: redirect("/articles/why-i-hate-five-star-ratings/")
  get "/blog/2012/02/07/collaborative-filtering-with-likes-and-dislikes", to: redirect("/articles/collaborative-filtering-with-likes-and-dislikes/")
  get "/blog/2012/07/18/the-current-state-of-rails-inflections", to: redirect("/articles/the-state-of-rails-inflections/")
  get "/blog/2012/07/31/edge-rails-a-multilingual-inflector", to: redirect("/articles/internationalization-and-the-rails-inflector/")
  get "/blog/2012/09/06/stop-validating-email-addresses-with-regex", to: redirect("/articles/stop-validating-email-addresses-with-regex/")
  get "/blog/2013/03/20/the-story-of-my-redis-database", to: redirect("/articles/from-1-5-gb-to-50-mb-the-story-of-my-redis-database/")
  get "/blog/2013/05/02/deploying-discourse-with-capistrano", to: redirect("/articles/deploying-discourse-with-capistrano/")
  get "/blog/2015/01/29/distance-constraints-with-postgresql-and-postgis", to: redirect("/articles/distance-constraints-with-postgresql-and-postgis/")

  get "/posts/why-i-hate-five-star-ratings", to: redirect("/articles/why-i-hate-five-star-ratings/")
  get "/posts/collaborative-filtering-with-likes-and-dislikes", to: redirect("/articles/collaborative-filtering-with-likes-and-dislikes/")
  get "/posts/the-current-state-of-rails-inflections", to: redirect("/articles/the-state-of-rails-inflections/")
  get "/posts/edge-rails-a-multilingual-inflector", to: redirect("/articles/internationalization-and-the-rails-inflector/")
  get "/posts/stop-validating-email-addresses-with-regex", to: redirect("/articles/stop-validating-email-addresses-with-regex/")
  get "/posts/the-story-of-my-redis-database", to: redirect("/articles/from-1-5-gb-to-50-mb-debugging-memory-usage-in-redis/")
  get "/posts/deploying-discourse-with-capistrano", to: redirect("/articles/deploying-discourse-with-capistrano/")
  get "/posts/distance-constraints-with-postgresql-and-postgis", to: redirect("/articles/distance-constraints-with-postgresql-and-postgis/")
  get "/posts/publish-your-site-to-s3", to: redirect("/articles/easily-publish-your-site-to-s3-and-cloudfront/")
end
