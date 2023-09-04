module Apple
  module WeatherKit
    ID = Rails.application.credentials.dig(:apple, :weather_kit_id).freeze

    def self.token(expires_in: 5.minutes)
      headers = {
        alg: "ES256",
        kid: Apple::KEY_ID,
        id: [Apple::TEAM_ID, Apple::WeatherKit::ID].join(".")
      }

      payload = {
        iss: Apple::TEAM_ID,
        iat: Time.now.to_i,
        exp: expires_in.from_now.to_i,
        sub: Apple::WeatherKit::ID
      }

      JWT.encode(payload, Apple::PRIVATE_KEY, "ES256", headers)
    end
  end
end
