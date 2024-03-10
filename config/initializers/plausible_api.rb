PlausibleApi.configure do |config|
  config.base_url = Rails.application.credentials.dig(:plausible, :base_url)
  config.site_id = Rails.application.credentials.dig(:plausible, :site_id)
  config.api_key = Rails.application.credentials.dig(:plausible, :api_key)
end
