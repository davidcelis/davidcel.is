module Apple
  module WeatherKit
    class CurrentWeather
      BASE_URL = "https://weatherkit.apple.com".freeze

      def self.at(latitude:, longitude:, as_of: nil)
        params = {dataSets: "currentWeather"}
        params[:currentAsOf] = as_of.iso8601 if as_of.present?

        connection.get("/api/v1/weather/en_US/#{latitude}/#{longitude}", params).body
      end

      def self.connection
        Faraday.new(BASE_URL) do |f|
          f.request :retry
          f.request :json
          f.request :authorization, "Bearer", Apple::WeatherKit.token

          f.response :raise_error
          f.response :json
        end
      end
    end
  end
end
