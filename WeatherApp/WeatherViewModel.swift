import Foundation
import SwiftUI
import Combine
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
      advice = AdviceEngine.makeAdvice(current: data.current, metrics: data.metrics)
    } catch {
      errorMessage = error.localizedDescription
    }
    isLoading = false
  }
}
