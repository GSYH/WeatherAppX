import Foundation

public struct Place: Codable, Identifiable, Hashable {
  public let id: UUID
  public let zip: String
  public let label: String
  public let latitude: Double
  public let longitude: Double
  public let lastUsedAt: Date

  public init(id: UUID = UUID(), zip: String, label: String, latitude: Double, longitude: Double, lastUsedAt: Date = Date()) {
    self.id = id
    self.zip = zip
    self.label = label
    self.latitude = latitude
    self.longitude = longitude
    self.lastUsedAt = lastUsedAt
  }
}

public struct WeatherMetrics: Codable, Hashable {
  public let humidity: Double?
  public let windMph: Double?
  public let feelsLikeF: Double?
  public let feelsLikeSource: String
}

public struct ForecastPeriod: Codable, Hashable, Identifiable {
  public let id: UUID
  public let name: String
  public let startTime: Date
  public let temperature: Double
  public let temperatureUnit: String
  public let shortForecast: String

  public init(name: String, startTime: Date, temperature: Double, temperatureUnit: String, shortForecast: String) {
    self.id = UUID()
    self.name = name
    self.startTime = startTime
    self.temperature = temperature
    self.temperatureUnit = temperatureUnit
    self.shortForecast = shortForecast
  }
}

public struct HourlyPeriod: Codable, Hashable, Identifiable {
  public let id: UUID
  public let startTime: Date
  public let temperature: Double
  public let temperatureUnit: String
  public let windSpeed: String
  public let probabilityOfPrecipitation: Double?
  public let shortForecast: String

  public init(startTime: Date, temperature: Double, temperatureUnit: String, windSpeed: String, probabilityOfPrecipitation: Double?, shortForecast: String) {
    self.id = UUID()
    self.startTime = startTime
    self.temperature = temperature
    self.temperatureUnit = temperatureUnit
    self.windSpeed = windSpeed
    self.probabilityOfPrecipitation = probabilityOfPrecipitation
    self.shortForecast = shortForecast
  }
}

public struct AlertItem: Codable, Hashable, Identifiable {
  public let id: UUID
  public let event: String
  public let headline: String
  public let severity: String
  public let effective: Date?
  public let expires: Date?

  public init(event: String, headline: String, severity: String, effective: Date?, expires: Date?) {
    self.id = UUID()
    self.event = event
    self.headline = headline
    self.severity = severity
    self.effective = effective
    self.expires = expires
  }
}

public struct WeatherSnapshot: Codable, Hashable {
  public let place: Place
  public let current: HourlyPeriod?
  public let hourly: [HourlyPeriod]
  public let daily: [ForecastPeriod]
  public let alerts: [AlertItem]
  public let metrics: WeatherMetrics
  public let updatedAt: Date
}

public struct ClothingAdvice: Codable, Hashable {
  public let summary: String
  public let details: [String]
}
