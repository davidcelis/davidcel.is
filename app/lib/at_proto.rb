module ATProto
  BASE_URL = Rails.application.credentials.dig(:at_proto, :url)
end
