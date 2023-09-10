module Apple
  module WeatherKit
    class CurrentWeather
      BASE_URL = "https://weatherkit.apple.com/api/v1/weather/en_US".freeze

      def self.at(latitude:, longitude:, as_of: nil)
        url = [BASE_URL, latitude, longitude].join("/")
        params = {dataSets: "currentWeather"}
        params[:currentAsOf] = as_of.iso8601 if as_of.present?
        headers = {"Authorization" => "Bearer #{Apple::WeatherKit.token}"}

        HTTParty.get url, query: params, headers: headers
      end
    end
  end
end
