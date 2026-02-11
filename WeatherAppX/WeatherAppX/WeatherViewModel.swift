import Foundation
import SwiftUI
import Combine
import CoreLocation
import WeatherCore

@MainActor
final class WeatherViewModel: ObservableObject {
  @Published var places: [Place] = []
  @Published var selectedPlace: Place?
  @Published var snapshot: WeatherSnapshot?
  @Published var advice: ClothingAdvice?
  @Published var isLoading = false
  @Published var errorMessage: String?
  @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
  @Published var isUsingCurrentLocation = false

  private let service = WeatherService(config: .init(userAgent: "NWSWidget/0.1 (contact: shuoyuan.g@gmail.com)"))
  private let locationManager = LocationManager()
  private var cancellables = Set<AnyCancellable>()

  init() {
    locationManager.$authorizationStatus
      .receive(on: DispatchQueue.main)
      .sink { [weak self] status in
        self?.authorizationStatus = status
      }
      .store(in: &cancellables)

    locationManager.$location
      .compactMap { $0 }
      .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
      .sink { [weak self] location in
        Task { await self?.loadForLocation(location) }
      }
      .store(in: &cancellables)

    locationManager.$lastErrorMessage
      .compactMap { $0 }
      .receive(on: DispatchQueue.main)
      .sink { [weak self] message in
        // Surface location failures (e.g. simulator location disabled) to the UI.
        self?.errorMessage = message
      }
      .store(in: &cancellables)
  }

  func requestLocationWhenInUse() {
    errorMessage = nil
    locationManager.requestWhenInUse()
  }

  func requestLocationAlways() {
    errorMessage = nil
    locationManager.requestAlways()
  }

  func startLocationIfAuthorized() {
    // We only need a one-shot fetch; LocationManager uses requestLocation().
    if authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse {
      locationManager.requestWhenInUse()
    }
  }

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

  private func loadForLocation(_ location: CLLocation) async {
    let place = Place(zip: "GPS", label: "Current Location", latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
    isUsingCurrentLocation = true
    selectedPlace = place
    await refresh()
  }
}
