module Apple
  module MapKit
    def self.token(expires_in: 5.minutes)
      headers = {
        alg: "ES256",
        kid: Apple::KEY_ID,
        typ: "JWT"
      }

      payload = {
        iss: Apple::TEAM_ID,
        iat: Time.now.to_i,
        exp: expires_in.from_now.to_i,
        origin: Rails.application.routes.url_helpers.root_url[0...-1]
      }

      JWT.encode(payload, Apple::PRIVATE_KEY, "ES256", headers)
    end
  end
end
