Sentry.init do |config|
  config.dsn = Rails.application.credentials.dig(:sentry, :dsn)
  config.breadcrumbs_logger = [:active_support_logger, :http_logger]

  # Don't use Sentry for performance monitoring.
  config.traces_sample_rate = 0

  # Capture request bodies; they can only come from me anyway.
  config.send_default_pii = true
end
