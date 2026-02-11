import Foundation

struct NWSPointsResponse: Codable {
  struct Properties: Codable {
    let forecast: URL
    let forecastHourly: URL
    let forecastGridData: URL
  }
  let properties: Properties
}

struct NWSForecastResponse: Decodable {
  struct Properties: Decodable {
    struct Period: Decodable {
      let name: String
      let startTime: Date
      let temperature: Double
      let temperatureUnit: String
      let shortForecast: String
    }
    let periods: [Period]
  }
  let properties: Properties
}

struct NWSHourlyResponse: Decodable {
  struct Properties: Decodable {
    struct Period: Decodable {
      struct Probability: Decodable { let value: Double? }
      let startTime: Date
      let temperature: Double
      let temperatureUnit: String
      let windSpeed: String
      let probabilityOfPrecipitation: Probability
      let shortForecast: String
    }
    let periods: [Period]
  }
  let properties: Properties
}

struct NWSAlertResponse: Decodable {
  struct Feature: Decodable {
    struct Properties: Decodable {
      let event: String
      let headline: String
      let severity: String
      let effective: Date?
      let expires: Date?
    }
    let properties: Properties
  }
  let features: [Feature]
}

struct NWSGridResponse: Decodable {
  struct Properties: Decodable {
    struct ValuePoint: Decodable {
      let validTime: String
      let value: Double?
    }
    let relativeHumidity: Humidity

    struct Humidity: Decodable {
      let values: [ValuePoint]
    }
  }
  let properties: Properties
}
