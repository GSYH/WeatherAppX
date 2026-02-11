import SwiftUI
import WeatherCore

struct ContentView: View {
  @EnvironmentObject private var viewModel: WeatherViewModel
  @State private var zipInput = ""

  var body: some View {
    ZStack {
      WeatherBackgroundView(effect: effectType)
      ScrollView {
        VStack(alignment: .leading, spacing: 16) {
          header
          currentSection
          adviceSection
          hourlySection
        }
        .padding(20)
      }
    }
    .task {
      if viewModel.selectedPlace != nil {
        await viewModel.refresh()
      }
    }
  }

  private var header: some View {
    HStack {
      VStack(alignment: .leading) {
        Text(viewModel.snapshot?.place.label ?? "Add a ZIP")
          .font(.title2).bold()
        if let updated = viewModel.snapshot?.updatedAt {
          Text("Updated \(updated.formatted(date: .omitted, time: .shortened))")
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
      }
      Spacer()
      HStack {
        TextField("ZIP", text: $zipInput)
          .textFieldStyle(.roundedBorder)
          .frame(width: 90)
        Button("Add") {
          Task { await viewModel.addZip(zipInput) }
        }
        .buttonStyle(.borderedProminent)
      }
    }
  }

  private var currentSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(alignment: .firstTextBaseline) {
        Text(currentTemp)
          .font(.system(size: 50, weight: .semibold))
        VStack(alignment: .leading) {
          Text(viewModel.snapshot?.current?.shortForecast ?? "-")
          Text(feelsLike)
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
      }
      HStack(spacing: 16) {
        metric("Wind", viewModel.snapshot?.current?.windSpeed ?? "-")
        metric("Precip", precip)
        metric("Humidity", humidity)
      }
    }
    .padding(16)
    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
  }

  private var adviceSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("What to wear")
        .font(.caption).foregroundStyle(.secondary)
      Text(viewModel.advice?.summary ?? "Add a ZIP to see advice")
      if let details = viewModel.advice?.details, !details.isEmpty {
        ForEach(details, id: \.self) { detail in
          Text("• \(detail)")
            .font(.footnote)
        }
      }
    }
    .padding(14)
    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
  }

  private var hourlySection: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Next Hours")
        .font(.caption).foregroundStyle(.secondary)
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 12) {
          ForEach(viewModel.snapshot?.hourly ?? []) { hour in
            VStack(spacing: 6) {
              Text(hour.startTime.formatted(.dateTime.hour()))
                .font(.caption)
              Text(formatTemp(hour.temperature, unit: hour.temperatureUnit))
                .font(.headline)
              Text("\(Int(hour.probabilityOfPrecipitation ?? 0))%")
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
            .padding(10)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
          }
        }
      }
    }
  }

  private var effectType: WeatherEffect {
    let text = (viewModel.snapshot?.current?.shortForecast ?? "").lowercased()
    if text.contains("thunder") { return .thunder }
    if text.contains("snow") || text.contains("sleet") { return .snow }
    if text.contains("rain") || text.contains("showers") { return .rain }
    if text.contains("fog") || text.contains("mist") { return .fog }
    if text.contains("cloud") || text.contains("overcast") { return .cloudy }
    return .clear
  }

  private var currentTemp: String {
    guard let current = viewModel.snapshot?.current else { return "--" }
    return formatTemp(current.temperature, unit: current.temperatureUnit)
  }

  private var feelsLike: String {
    guard let metrics = viewModel.snapshot?.metrics, let value = metrics.feelsLikeF else { return "Feels like --" }
    let c = (value - 32) * 5 / 9
    return "Feels like \(Int(c.rounded()))°C"
  }

  private var humidity: String {
    if let h = viewModel.snapshot?.metrics.humidity {
      return "\(Int(h.rounded()))%"
    }
    return "-"
  }

  private var precip: String {
    if let p = viewModel.snapshot?.current?.probabilityOfPrecipitation {
      return "\(Int(p.rounded()))%"
    }
    return "-"
  }

  private func metric(_ label: String, _ value: String) -> some View {
    VStack(alignment: .leading) {
      Text(label).font(.caption).foregroundStyle(.secondary)
      Text(value).font(.subheadline)
    }
  }

  private func formatTemp(_ value: Double, unit: String) -> String {
    let c = unit == "C" ? value : (value - 32) * 5 / 9
    return "\(Int(c.rounded()))°C"
  }
}

#Preview {
  ContentView()
    .environmentObject(WeatherViewModel())
}
