import Foundation

public actor WeatherService {
  public struct Configuration {
    public let userAgent: String
    public let cache: FileCache

    public init(userAgent: String, cache: FileCache = FileCache()) {
      self.userAgent = userAgent
      self.cache = cache
    }
  }

  private let config: Configuration
  private let session: URLSession
  private let decoder: JSONDecoder

  public init(config: Configuration) {
    self.config = config
    self.session = URLSession(configuration: .default)
    self.decoder = JSONDecoder()
    self.decoder.dateDecodingStrategy = .iso8601
  }

  public func lookupPlace(zip: String) async throws -> Place {
    let cacheKey = "geo-\(zip).json"
    if let cached: Place = config.cache.load(Place.self, key: cacheKey) {
      return cached
    }

    let url = URL(string: "https://api.zippopotam.us/us/\(zip)")!
    let response: ZippopotamResponse = try await request(url)
    guard let place = response.places.first,
          let lat = Double(place.latitude),
          let lon = Double(place.longitude) else {
      throw NSError(domain: "WeatherService", code: 404, userInfo: [NSLocalizedDescriptionKey: "ZIP not found"])
    }

    let label = "\(place.placeName), \(place.stateAbbreviation)"
    let result = Place(zip: zip, label: label, latitude: lat, longitude: lon)
    config.cache.save(result, key: cacheKey)
    return result
  }

  public func loadWeather(for place: Place) async throws -> WeatherSnapshot {
    let points = try await loadPoints(lat: place.latitude, lon: place.longitude)

    async let forecast: NWSForecastResponse = request(points.forecast)
    async let hourly: NWSHourlyResponse = request(points.forecastHourly)
    async let grid: NWSGridResponse = request(points.forecastGridData)
    async let alertsResponse: NWSAlertResponse = request(URL(string: "https://api.weather.gov/alerts/active?point=\(place.latitude),\(place.longitude)")!)

    let forecastResult = try await forecast
    let hourlyResult = try await hourly
    let gridResult = try await grid
    let alertResult = try await alertsResponse

    let hourlyPeriods = hourlyResult.properties.periods.map {
      HourlyPeriod(
        startTime: $0.startTime,
        temperature: $0.temperature,
        temperatureUnit: $0.temperatureUnit,
        windSpeed: $0.windSpeed,
        probabilityOfPrecipitation: $0.probabilityOfPrecipitation.value,
        shortForecast: $0.shortForecast
      )
    }

    let dailyPeriods = forecastResult.properties.periods.map {
      ForecastPeriod(
        name: $0.name,
        startTime: $0.startTime,
        temperature: $0.temperature,
        temperatureUnit: $0.temperatureUnit,
        shortForecast: $0.shortForecast
      )
    }

    let alertItems = alertResult.features.map {
      AlertItem(
        event: $0.properties.event,
        headline: $0.properties.headline,
        severity: $0.properties.severity,
        effective: $0.properties.effective,
        expires: $0.properties.expires
      )
    }

    let current = hourlyPeriods.first
    let humidity = pickGridValue(gridResult.properties.relativeHumidity.values, at: current?.startTime)
    let windMph = parseWindMph(current?.windSpeed)
    let tempF = current.map { $0.temperatureUnit == "F" ? $0.temperature : ($0.temperature * 9 / 5 + 32) }
    let windChill = tempF.flatMap { windChillF(tempF: $0, windMph: windMph) }
    let heatIndex = tempF.flatMap { heatIndexF(tempF: $0, humidity: humidity) }
    let feels = heatIndex ?? windChill ?? tempF
    let source = heatIndex != nil ? "heat-index" : windChill != nil ? "wind-chill" : "temperature"

    let metrics = WeatherMetrics(humidity: humidity, windMph: windMph, feelsLikeF: feels, feelsLikeSource: source)

    return WeatherSnapshot(
      place: place,
      current: current,
      hourly: Array(hourlyPeriods.prefix(24)),
      daily: Array(dailyPeriods.prefix(7)),
      alerts: alertItems,
      metrics: metrics,
      updatedAt: Date()
    )
  }

  private func loadPoints(lat: Double, lon: Double) async throws -> NWSPointsResponse.Properties {
    let cacheKey = "points-\(lat)-\(lon).json"
    if let cached: NWSPointsResponse.Properties = config.cache.load(NWSPointsResponse.Properties.self, key: cacheKey) {
      return cached
    }
    let url = URL(string: "https://api.weather.gov/points/\(lat),\(lon)")!
    let response: NWSPointsResponse = try await request(url)
    config.cache.save(response.properties, key: cacheKey)
    return response.properties
  }

  private func request<T: Decodable>(_ url: URL) async throws -> T {
    var req = URLRequest(url: url)
    req.setValue(config.userAgent, forHTTPHeaderField: "User-Agent")
    req.setValue("application/geo+json, application/json", forHTTPHeaderField: "Accept")

    let (data, response) = try await session.data(for: req)
    if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
      let body = String(data: data, encoding: .utf8) ?? ""
      throw NSError(domain: "WeatherService", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: body])
    }
    return try decoder.decode(T.self, from: data)
  }
}

private func parseWindMph(_ windSpeed: String?) -> Double? {
  guard let windSpeed else { return nil }
  let parts = windSpeed.split(separator: " ")
  if let value = Double(parts.first ?? "") { return value }
  return nil
}

private func pickGridValue(_ values: [NWSGridResponse.Properties.ValuePoint], at time: Date?) -> Double? {
  guard let time else { return nil }
  let target = time.timeIntervalSince1970
  var best: (Double, Double?)? = nil
  for entry in values {
    let start = entry.validTime.split(separator: "/").first ?? ""
    if let date = ISO8601DateFormatter().date(from: String(start)) {
      let delta = abs(date.timeIntervalSince1970 - target)
      if best == nil || delta < best!.0 {
        best = (delta, entry.value)
      }
    }
  }
  return best?.1
}

private func windChillF(tempF: Double, windMph: Double?) -> Double? {
  guard let windMph, tempF <= 50, windMph >= 3 else { return nil }
  return 35.74 + 0.6215 * tempF - 35.75 * pow(windMph, 0.16) + 0.4275 * tempF * pow(windMph, 0.16)
}

private func heatIndexF(tempF: Double, humidity: Double?) -> Double? {
  guard let humidity, tempF >= 80, humidity >= 40 else { return nil }
  let t = tempF
  let rh = humidity
  return -42.379 + 2.04901523 * t + 10.14333127 * rh - 0.22475541 * t * rh - 0.00683783 * t * t - 0.05481717 * rh * rh + 0.00122874 * t * t * rh + 0.00085282 * t * rh * rh - 0.00000199 * t * t * rh * rh
}
