import SwiftUI
import WeatherCore

struct ContentView: View {
  @EnvironmentObject private var viewModel: WeatherViewModel
  @State private var zipInput = ""

  var body: some View {
    ZStack {
      WeatherBackgroundView(effect: effectType)
      ScrollView(showsIndicators: false) {
        VStack(alignment: .leading, spacing: 22) {
          header
          currentSection
          adviceSection
          hourlySection
        }
        .padding(.horizontal, 22)
        .padding(.top, 26)
        .padding(.bottom, 32)
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
      VStack(alignment: .leading, spacing: 4) {
        Text(viewModel.snapshot?.place.label ?? "Add a ZIP")
          .font(.system(size: 28, weight: .semibold))
        if let updated = viewModel.snapshot?.updatedAt {
          Text("Updated \(updated.formatted(date: .omitted, time: .shortened))")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
      Spacer()
      HStack {
        TextField("ZIP", text: $zipInput)
          .textFieldStyle(.roundedBorder)
          .frame(width: 96)
        Button("Add") {
          Task { await viewModel.addZip(zipInput) }
        }
        .buttonStyle(.borderedProminent)
      }
    }
  }

  private var currentSection: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(alignment: .firstTextBaseline, spacing: 12) {
        Text(currentTemp)
          .font(.system(size: 64, weight: .semibold))
        VStack(alignment: .leading, spacing: 4) {
          Text(viewModel.snapshot?.current?.shortForecast ?? "-")
            .font(.system(size: 16, weight: .medium))
          Text(feelsLike)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
      HStack(spacing: 18) {
        metric("Wind", viewModel.snapshot?.current?.windSpeed ?? "-")
        metric("Precip", precip)
        metric("Humidity", humidity)
      }
    }
    .padding(18)
    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    .shadow(color: .black.opacity(0.08), radius: 18, x: 0, y: 10)
  }

  private var adviceSection: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text("What to wear")
        .font(.caption).foregroundStyle(.secondary)
      Text(viewModel.advice?.summary ?? "Add a ZIP to see advice")
      if let details = viewModel.advice?.details, !details.isEmpty {
        ForEach(details, id: \.self) { detail in
          Text("• \(detail)")
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
      }
    }
    .padding(16)
    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 6)
  }

  private var hourlySection: some View {
    VStack(alignment: .leading, spacing: 10) {
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
            .padding(12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 6)
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
    VStack(alignment: .leading, spacing: 2) {
      Text(label).font(.caption).foregroundStyle(.secondary)
      Text(value).font(.subheadline).fontWeight(.medium)
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
