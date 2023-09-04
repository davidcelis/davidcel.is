module Apple
  module WeatherKit
    class CurrentWeather
      BASE_URL = "https://weatherkit.apple.com/api/v1/weather/en_US".freeze

      def self.at(latitude:, longitude:)
        url = [BASE_URL, latitude, longitude].join("/")
        params = {dataSets: "currentWeather"}
        headers = {"Authorization" => "Bearer #{Apple::WeatherKit.token}"}

        HTTParty.get url, query: params, headers: headers
      end
    end
  end
end
