import SwiftUI
import WeatherCore

@main
struct WeatherApp: App {
  @StateObject private var viewModel = WeatherViewModel()

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environmentObject(viewModel)
    }
  }
}
