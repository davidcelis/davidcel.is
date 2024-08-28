class AddWeatherToPostJob < ApplicationJob
  def perform(post_id)
    post = Post.find(post_id)
    post.weather ||= {}

    response = Apple::WeatherKit::CurrentWeather.at(latitude: post.latitude, longitude: post.longitude, as_of: post.created_at)
    post.weather.merge!(response["currentWeather"])

    post.save!
  rescue Faraday::Error
    # Just keep trying every five minutes rather than relying on Sidekiq's
    # retry mechanism with an exponential backoff. This way, it can retry
    # indefinitely at a reasonable rate until it works.
    self.class.perform_in(5.minutes, post_id)
  end
end
