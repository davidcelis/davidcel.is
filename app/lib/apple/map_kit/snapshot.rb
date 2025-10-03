module Apple
  module MapKit
    class Snapshot
      BASE_URL = "https://snapshot.apple-mapkit.com".freeze

      attr_reader :url

      def initialize(point:)
        params = {
          center: point,
          scale: 3,
          z: 15,
          annotations: [{point: "center", color: "ec4899"}].to_json,
          teamId: Apple::TEAM_ID,
          keyId: Apple::KEY_ID
        }

        unsigned_path ||= "/api/v1/snapshot?#{params.to_query}"
        signer = JWT::JWA::Ecdsa.new("ES256", "SHA256")
        signature = signer.sign(data: unsigned_path, signing_key: Apple::PRIVATE_KEY)
        encoded_signature = JWT::Base64.url_encode(signature)

        @url = "#{BASE_URL}#{unsigned_path}&signature=#{encoded_signature}"
      end
    end
  end
end
