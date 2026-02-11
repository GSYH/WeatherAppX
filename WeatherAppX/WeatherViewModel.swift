import Foundation
import SwiftUI
import WeatherCore

@MainActor
final class WeatherViewModel: ObservableObject {
  @Published var places: [Place] = []
  @Published var selectedPlace: Place?
  @Published var snapshot: WeatherSnapshot?
  @Published var advice: ClothingAdvice?
  @Published var isLoading = false
  @Published var errorMessage: String?

  private let service = WeatherService(config: .init(userAgent: "NWSWidget/0.1 (contact: shuoyuan.g@gmail.com)"))
  private var userProfile: UserProfile = .standard

  func addZip(_ zip: String) async {
    errorMessage = nil
    isLoading = true
    do {
      let place = try await service.lookupPlace(zip: zip)
      if !places.contains(place) {
        places.insert(place, at: 0)
      }
      selectedPlace = place
      await refresh()
    } catch {
      errorMessage = error.localizedDescription
    }
    isLoading = false
  }

  func refresh() async {
    guard let selectedPlace else { return }
    isLoading = true
    errorMessage = nil
    do {
      let data = try await service.loadWeather(for: selectedPlace)
      snapshot = data
      
      // Map to Recommendation Engine Weather Model
      if let current = data.current {
          let tempC = current.temperatureUnit == "F" ? (current.temperature - 32) * 5/9 : current.temperature
          
          let feelsLikeF = data.metrics.feelsLikeF ?? current.temperature // fallback
          let feelsLikeC = (feelsLikeF - 32) * 5/9
          
          let windMph = data.metrics.windMph ?? 0
          
          let precipProb = (current.probabilityOfPrecipitation ?? 0) / 100.0 // Convert 0-100 to 0.0-1.0
          
          let humidity = data.metrics.humidity ?? 0
          
          let weather = Weather(
              temperature: tempC,
              feelsLike: feelsLikeC,
              windSpeed: windMph,
              precipitationProbability: precipProb,
              humidity: humidity
          )
          
          let recommendation = OutfitRecommendationEngine.generateOutfitRecommendation(weather: weather, user: userProfile)
          
          // Map back to ClothingAdvice for View compatibility
          advice = ClothingAdvice(
              summary: recommendation.summaryText,
              details: recommendation.explanation
          )
      } else {
           advice = AdviceEngine.makeAdvice(current: data.current, metrics: data.metrics)
      }
      
    } catch {
      errorMessage = error.localizedDescription
    }
    isLoading = false
  }
}
