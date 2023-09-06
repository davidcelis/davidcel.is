module WeatherHelper
  # Map all of the WeatherKit condition codes to a corresponding icon. Some of
  # the icons support a day and night variant, so we'll use the weather data's
  # `daylight` property to determine which icon to use.
  CONDITIONS = {
    # Visibility conditions
    "BlowingDust" => Hash.new("sun.dust"),
    "Clear" => {
      true => "sun.max",
      false => "moon.stars"
    },
    "Cloudy" => Hash.new("cloud"),
    "Foggy" => Hash.new("cloud.fog"),
    "Haze" => {
      true => "sun.haze",
      false => "moon.haze"
    },
    "MostlyClear" => {
      true => "sun.min",
      false => "moon"
    },
    "MostlyCloudy" => {
      true => "cloud",
      false => "cloud"
    },
    "PartlyCloudy" => {
      true => "cloud.sun",
      false => "cloud.moon"
    },
    "Smoky" => Hash.new("smoke"),

    # Wind conditions
    "Breezy" => Hash.new("wind"),
    "Windy" => Hash.new("wind"),

    # Precipitation conditions
    "SunShowers" => {
      true => "cloud.sun.rain",
      false => "cloud.moon.rain"
    },
    "Drizzle" => Hash.new("cloud.drizzle"),
    "Rain" => Hash.new("cloud.rain"),
    "HeavyRain" => Hash.new("cloud.heavyrain"),
    "IsolatedThunderstorms" => {
      true => "cloud.sun.bolt",
      false => "cloud.moon.bolt"
    },
    "ScatteredThunderstorms" => Hash.new("cloud.bolt"),
    "Thunderstorms" => Hash.new("cloud.bolt.rain"),
    "StrongStorms" => Hash.new("cloud.bolt.rain"),

    # Hazardous conditions
    "Frigid" => Hash.new("thermometer.snowflake"),
    "Hail" => Hash.new("cloud.hail"),
    "Hot" => Hash.new("thermometer.sun"),

    # Winter precipitation conditions
    "Flurries" => Hash.new("cloud.snow"),
    "Sleet" => Hash.new("cloud.sleet"),
    "Snow" => Hash.new("snowflake"),
    "SunFlurries" => Hash.new("cloud.snow"),
    "WintryMix" => Hash.new("cloud.sleet"),

    # Hazardous winter conditions
    "Blizzard" => Hash.new("snowflake"),
    "BlowingSnow" => Hash.new("wind.snow"),
    "FreezingDrizzle" => Hash.new("cloud.sleet"),
    "FreezingRain" => Hash.new("cloud.sleet"),
    "HeavySnow" => Hash.new("cloud.snow"),

    # Tropical hazards
    "Hurricane" => Hash.new("hurricane"),
    "TropicalStorm" => Hash.new("tropicalstorm")
  }.freeze

  def weather_icon_url(post)
    return unless post.weather.present?

    condition = post.weather["conditionCode"]
    daylight = post.weather["daylight"]

    if (icon = CONDITIONS.dig(condition, daylight))
      image_url("weather/#{icon}.png")
    end
  end
end
