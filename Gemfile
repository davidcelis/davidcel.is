source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.3.0"

gem "rails", "~> 7.1.0"

# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem "propshaft"

# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"
gem "pg_search", "~> 2.3"

# Use the Puma web server [https://github.com/puma/puma]
gem "puma", "~> 6.0"

# Use CommonMark to render posts as HTML [https://github.com/gjtorikian/commonmarker]
gem "commonmarker", "~> 0.23"

# Parse webmentions with microformats
gem "microformats", github: "microformats/microformats-ruby"

# Use Pagy to paginate through collections
gem "pagy", "~> 5.10"

# Use Avo to generate an admin interface
gem "avo"

# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"

# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"

# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"

# Use Tailwind CSS [https://github.com/rails/tailwindcss-rails]
gem "tailwindcss-rails"

# Use Redis adapter to run Action Cable in production
gem "redis", "~> 4.0"

# Use Sidekiq to perform asynchronous jobs
gem "sidekiq", "~> 7.0"
gem "sidekiq-scheduler", "~> 5.0"

# Use ImageProcessing to handle ActiveStorage variants
gem "image_processing", ">= 1.12"
gem "ruby-vips"

# Upload ActiveStorage files to DigitalOcean Spaces
gem "aws-sdk-s3"

# Construct and sign JWTs for use with Apple MapKit JS
gem "jwt"

# Use Faraday for external HTTP/API requests and clients
gem "faraday"
gem "faraday-retry"
gem "faraday-multipart"

# Use Sentry for error reporting
gem "sentry-ruby"
gem "sentry-rails"
gem "sentry-sidekiq"

# Tame Rails' logging
gem "lograge"

# Monitor performance with Skylight
gem "skylight"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

group :development, :test do
  gem "pry-byebug"
  gem "pry-rails"

  gem "rspec-rails", "~> 6"
  gem "webmock"
  gem "vcr"

  gem "standardrb"
end

group :development do
  gem "ruby-lsp"

  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"

  # Add speed badges [https://github.com/MiniProfiler/rack-mini-profiler]
  # gem "rack-mini-profiler"

  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  # gem "spring"
end
