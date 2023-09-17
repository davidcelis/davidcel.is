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

  EMOJI = {
    "BlowingDust" => Hash.new("💨"),
    "Clear" => {
      true => "☀️",
      false => "🌙"
    },
    "Cloudy" => Hash.new("☁️\uFE0F"),
    "Foggy" => Hash.new("🌫"),
    "Haze" => {
      true => "🌤",
      false => "🌫"
    },
    "MostlyClear" => {
      true => "🌤",
      false => "🌙"
    },
    "MostlyCloudy" => {
      true => "🌥️",
      false => "☁️"
    },
    "PartlyCloudy" => {
      true => "⛅",
      false => "🌙"
    },
    "Smoky" => Hash.new("🌫"),
    "Breezy" => Hash.new("💨"),
    "Windy" => Hash.new("💨"),
    "SunShowers" => {
      true => "🌦️",
      false => "🌧️"
    },
    "Drizzle" => Hash.new("🌧️"),
    "Rain" => Hash.new("🌧️"),
    "HeavyRain" => Hash.new("🌧️"),
    "IsolatedThunderstorms" => Hash.new("🌩️"),
    "ScatteredThunderstorms" => Hash.new("🌩️"),
    "Thunderstorms" => Hash.new("⛈️"),
    "StrongStorms" => Hash.new("⛈️"),
    "Frigid" => Hash.new("🥶"),
    "Hail" => Hash.new("🌧️"),
    "Hot" => Hash.new("🥵"),
    "Flurries" => Hash.new("🌨️"),
    "Sleet" => Hash.new("🌨️"),
    "Snow" => Hash.new("🌨️"),
    "SunFlurries" => Hash.new("🌨️"),
    "WintryMix" => Hash.new("🌨️"),
    "Blizzard" => Hash.new("🌨️"),
    "BlowingSnow" => Hash.new("🌨️"),
    "FreezingDrizzle" => Hash.new("🌨️"),
    "FreezingRain" => Hash.new("🌨️"),
    "HeavySnow" => Hash.new("🌨️"),
    "Hurricane" => Hash.new("🌀"),
    "TropicalStorm" => Hash.new("🌀")
  }.freeze

  FRIENDLY_CONDITIONS = {
    "BlowingDust" => "and dusty",
    "Clear" => "and clear",
    "Cloudy" => "and cloudy",
    "Foggy" => "and foggy",
    "Haze" => "and hazy",
    "MostlyClear" => "and mostly clear",
    "MostlyCloudy" => "and mostly cloudy",
    "PartlyCloudy" => "and partly cloudy",
    "Smoky" => "and smoky",
    "Breezy" => "and breezy",
    "Windy" => "and windy",
    "SunShowers" => "with sun showers",
    "Drizzle" => "and drizzling",
    "Rain" => "and raining",
    "HeavyRain" => "and raining heavily",
    "IsolatedThunderstorms" => "with isolated thunderstorms",
    "ScatteredThunderstorms" => "with scattered thunderstorms",
    "Thunderstorms" => "with thunderstorms",
    "StrongStorms" => "with strong thunderstorms",
    "Frigid" => "and frigid",
    "Hail" => "and hailing",
    "Hot" => "and hot",
    "Flurries" => "with flurries",
    "Sleet" => "with sleet",
    "Snow" => "and snowing",
    "SunFlurries" => "with sun flurries",
    "WintryMix" => "with a wintry mix",
    "Blizzard" => "with blizzard conditions",
    "BlowingSnow" => "and blowing snow",
    "FreezingDrizzle" => "with a freezing drizzle",
    "FreezingRain" => "with freezing rain",
    "HeavySnow" => "and snowing heavily",
    "Hurricane" => "with hurricane conditions",
    "TropicalStorm" => "with tropical storm conditions"
  }.freeze

  def weather_icon_url(post)
    return unless post.weather.present?

    condition = post.weather["conditionCode"]
    daylight = post.weather["daylight"]

    if (icon = CONDITIONS.dig(condition, daylight))
      image_url("weather/#{icon}.png")
    end
  end

  def weather_emoji(post)
    return unless post.weather.present?

    condition = post.weather["conditionCode"]
    daylight = post.weather["daylight"]

    EMOJI.dig(condition, daylight)
  end

  def weather_conditions(post)
    return unless post.weather.present?

    FRIENDLY_CONDITIONS[post.weather["conditionCode"]]
  end
end
