import Foundation

public struct AdviceEngine {
  public static func makeAdvice(current: HourlyPeriod?, metrics: WeatherMetrics) -> ClothingAdvice {
    guard let current else {
      return ClothingAdvice(summary: "Add a ZIP to see advice.", details: [])
    }

    let tempF = current.temperatureUnit == "F" ? current.temperature : (current.temperature * 9 / 5 + 32)
    let feelsF = metrics.feelsLikeF ?? tempF
    let feelsC = (feelsF - 32) * 5 / 9

    var summary: String
    if feelsC <= 0 { summary = "Heavy coat, warm base layer, gloves and a hat." }
    else if feelsC <= 10 { summary = "Thick jacket and a scarf." }
    else if feelsC <= 20 { summary = "Light jacket or sweatshirt." }
    else if feelsC <= 27 { summary = "Short sleeves or a thin long-sleeve." }
    else { summary = "Light, breathable clothes." }

    var details: [String] = []
    if let pop = current.probabilityOfPrecipitation, pop >= 50 {
      details.append("Bring an umbrella or a waterproof layer.")
    }
    if let wind = metrics.windMph, wind >= 15 {
      details.append("A windbreaker will help.")
    }
    if let humidity = metrics.humidity, humidity >= 70, feelsC >= 24 {
      details.append("High humidity: choose moisture-wicking fabrics.")
    }

    return ClothingAdvice(summary: summary, details: details)
  }
}
