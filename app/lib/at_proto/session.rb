module ATProto
  class Session
    BASE_PATH = "/xrpc/com.atproto.server".freeze

    attr_reader :access_token, :refresh_token, :handle, :did, :email, :pds_endpoint_uri

    def initialize(identifier:, password:)
      params = {identifier: identifier, password: password}
      response = connection.post("#{BASE_PATH}.createSession", params.to_json)

      @access_token = response.body["accessJwt"]
      @refresh_token = response.body["refreshJwt"]
      @handle = response.body["handle"]
      @did = response.body["did"]
      @email = response.body["email"]

      services = response.body.dig("didDoc", "service")
      pds = services.find { |service| service["type"] == "AtprotoPersonalDataServer" }
      @pds_endpoint_uri = URI.parse(pds["serviceEndpoint"])
    end

    def destroy!
      connection.post("#{BASE_PATH}.deleteSession", nil, {"Authorization" => "Bearer #{@refresh_token}"})
    end

    private

    def connection
      @connection ||= Faraday.new(ATProto::BASE_URL) do |f|
        f.request :retry
        f.request :json

        f.response :raise_error
        f.response :json
      end
    end
  end
end
