import Foundation
import CoreLocation
import Combine

final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
  private let manager = CLLocationManager()

  @Published var authorizationStatus: CLAuthorizationStatus
  @Published var location: CLLocation?
  @Published var lastErrorMessage: String?

  override init() {
    self.authorizationStatus = manager.authorizationStatus
    super.init()
    manager.delegate = self
    manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
  }

  func requestWhenInUse() {
    manager.requestWhenInUseAuthorization()
    // If the user already granted permission, this will fetch immediately.
    if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
      manager.requestLocation()
    }
  }

  func requestAlways() {
    manager.requestAlwaysAuthorization()
    if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
      manager.requestLocation()
    }
  }

  func startUpdating() {
    manager.startUpdatingLocation()
  }

  func stopUpdating() {
    manager.stopUpdatingLocation()
  }

  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    authorizationStatus = manager.authorizationStatus
    if authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse {
      // One-shot update is enough for our UI; avoids background churn.
      manager.requestLocation()
    }
  }

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    location = locations.last
    lastErrorMessage = nil
  }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    lastErrorMessage = error.localizedDescription
  }
}
