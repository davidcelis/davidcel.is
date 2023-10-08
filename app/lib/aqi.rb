class AQI
  BASE_URL = "https://api.waqi.info"
  TOKEN = Rails.application.credentials.dig(:aqi, :token)

  def self.at(latitude:, longitude:)
    connection.get("/feed/geo:#{latitude};#{longitude}", token: TOKEN).body.dig("data", "aqi")
  end

  def self.connection
    Faraday.new(BASE_URL) do |f|
      f.request :retry

      f.response :raise_error
      f.response :json
    end
  end
end
