module Apple
  PRIVATE_KEY = OpenSSL::PKey::EC.new(Rails.application.credentials.dig(:apple, :private_key)).freeze
  TEAM_ID = Rails.application.credentials.dig(:apple, :team_id).freeze
  KEY_ID = Rails.application.credentials.dig(:apple, :key_id).freeze
end
