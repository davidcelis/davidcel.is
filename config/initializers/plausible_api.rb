PlausibleApi.configure do |config|
  config.base_url = Rails.application.credentials.dig(:plausible, :base_url)
end
