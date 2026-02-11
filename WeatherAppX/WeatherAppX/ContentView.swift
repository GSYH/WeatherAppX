import SwiftUI
import WeatherCore

struct ContentView: View {
  @EnvironmentObject private var viewModel: WeatherViewModel
  @State private var zipInput = ""
  @State private var showSearch = false
  @FocusState private var zipFieldFocused: Bool

  var body: some View {
    ZStack {
      if viewModel.snapshot == nil && !viewModel.isLoading {
        // Onboarding uses video background if present in bundle.
        VideoLoopView(resourceName: "STG_pow-2", resourceExtension: "mp4")
      } else {
        WeatherBackgroundView(effect: effectType)
      }
      if viewModel.snapshot == nil && !viewModel.isLoading {
        onboarding
      } else {
        ScrollView(showsIndicators: false) {
          VStack(alignment: .leading, spacing: 22) {
            header
            currentSection
            adviceSection
            hourlySection
            dailySection
            footerAttribution
          }
          .padding(.horizontal, 22)
          .padding(.top, 26)
          .padding(.bottom, 32)
        }
      }
    }
    .task {
      viewModel.startLocationIfAuthorized()
      if viewModel.selectedPlace != nil {
        await viewModel.refresh()
      }
    }
    .sheet(isPresented: $showSearch) {
      searchSheet
    }
  }

  private var header: some View {
    HStack {
      VStack(alignment: .leading, spacing: 4) {
        Text(viewModel.snapshot?.place.label ?? "Current Location")
          .font(.system(size: 28, weight: .semibold))
        if let updated = viewModel.snapshot?.updatedAt {
          Text("Updated \(updated.formatted(date: .omitted, time: .shortened))")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
      Spacer()
      Button {
        showSearch = true
      } label: {
        Image(systemName: "magnifyingglass")
          .font(.system(size: 16, weight: .semibold))
          .foregroundStyle(.primary)
          .frame(width: 36, height: 36)
          .background(.ultraThinMaterial, in: Circle())
      }
    }
  }

  private var onboarding: some View {
    VStack {
      VStack(spacing: 18) {
        VStack(spacing: 6) {
          Text("想查询哪里的天气？")
            .font(.system(size: 24, weight: .semibold))
          Text("输入 ZIP Code，或使用当前位置。")
            .font(.footnote)
            .foregroundStyle(.secondary)
        }

        HStack(spacing: 10) {
          TextField("ZIP Code", text: $zipInput)
            .keyboardType(.numberPad)
            .textContentType(.postalCode)
            .textFieldStyle(.roundedBorder)
            .frame(width: 170)
            .focused($zipFieldFocused)
          Button {
            zipFieldFocused = false
            Task { await viewModel.addZip(zipInput) }
          } label: {
            Image(systemName: "magnifyingglass")
              .font(.system(size: 16, weight: .semibold))
              .frame(width: 44, height: 44)
          }
          .buttonStyle(.borderedProminent)
        }

        Button {
          zipFieldFocused = false
          viewModel.requestLocationWhenInUse()
        } label: {
          HStack(spacing: 8) {
            Image(systemName: "location.fill")
            Text("使用当前位置")
          }
          .frame(maxWidth: .infinity)
          .frame(height: 44)
        }
        .buttonStyle(.bordered)

        Text("我们会先询问定位权限，默认仅在使用期间访问。")
          .font(.caption2)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)

        if let error = viewModel.errorMessage, !error.isEmpty {
          Text(error)
            .font(.caption2)
            .foregroundStyle(.red.opacity(0.9))
            .multilineTextAlignment(.center)
            .padding(.top, 4)
        }
      }
      .padding(24)
      .frame(maxWidth: 420)
      .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius: 26, style: .continuous)
          .stroke(
            LinearGradient(
              colors: [
                .white.opacity(0.55),
                .white.opacity(0.12),
                .white.opacity(0.05)
              ],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            ),
            lineWidth: 1
          )
      )
      .shadow(color: .black.opacity(0.10), radius: 22, x: 0, y: 14)
      .padding(.horizontal, 24)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
  }

  private var searchSheet: some View {
    NavigationStack {
      VStack(alignment: .leading, spacing: 16) {
        Text("添加位置")
          .font(.headline)
        HStack {
          TextField("ZIP Code", text: $zipInput)
            .keyboardType(.numberPad)
            .textFieldStyle(.roundedBorder)
          Button("添加") {
            Task { await viewModel.addZip(zipInput) }
          }
          .buttonStyle(.borderedProminent)
        }
        if !viewModel.places.isEmpty {
          Text("已保存位置")
            .font(.caption)
            .foregroundStyle(.secondary)
          ForEach(viewModel.places, id: \.id) { place in
            Button {
              viewModel.selectedPlace = place
              Task { await viewModel.refresh() }
              showSearch = false
            } label: {
              HStack {
                Text(place.label)
                Spacer()
              }
            }
            .buttonStyle(.plain)
          }
        }
        Spacer()
      }
      .padding(20)
      .navigationTitle("搜索")
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("完成") { showSearch = false }
        }
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
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 22, style: .continuous)
        .stroke(
          LinearGradient(
            colors: [
              .white.opacity(0.55),
              .white.opacity(0.12),
              .white.opacity(0.05)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          ),
          lineWidth: 1
        )
    )
    .overlay(
      RoundedRectangle(cornerRadius: 22, style: .continuous)
        .fill(
          LinearGradient(
            colors: [
              .white.opacity(0.12),
              .white.opacity(0.02)
            ],
            startPoint: .top,
            endPoint: .bottom
          )
        )
        .blendMode(.screen)
    )
    .shadow(color: .black.opacity(0.06), radius: 14, x: 0, y: 10)
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
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 18, style: .continuous)
        .stroke(
          LinearGradient(
            colors: [
              .white.opacity(0.45),
              .white.opacity(0.10)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          ),
          lineWidth: 1
        )
    )
    .overlay(
      RoundedRectangle(cornerRadius: 18, style: .continuous)
        .fill(
          LinearGradient(
            colors: [
              .white.opacity(0.10),
              .white.opacity(0.01)
            ],
            startPoint: .top,
            endPoint: .bottom
          )
        )
        .blendMode(.screen)
    )
    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 6)
  }

  private var hourlySection: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text("Next Hours")
        .font(.caption).foregroundStyle(.secondary)
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 14) {
          ForEach(viewModel.snapshot?.hourly ?? []) { hour in
            VStack(spacing: 6) {
              Text(hour.startTime.formatted(.dateTime.hour()))
                .font(.caption)
                .foregroundStyle(.secondary)
              Text(formatTemp(hour.temperature, unit: hour.temperatureUnit))
                .font(.headline)
              Text("\(Int(hour.probabilityOfPrecipitation ?? 0))%")
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
            .frame(width: 62)
          }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius: 20, style: .continuous)
          .stroke(
            LinearGradient(
              colors: [
                .white.opacity(0.40),
                .white.opacity(0.08)
              ],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            ),
            lineWidth: 1
          )
      )
      .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 6)
    }
  }

  private var dailySection: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text("Next 7 Days")
        .font(.caption).foregroundStyle(.secondary)
      VStack(spacing: 0) {
        ForEach(Array((viewModel.snapshot?.daily ?? []).enumerated()), id: \.element.id) { index, day in
          HStack {
            Text(day.name)
              .font(.subheadline)
              .foregroundStyle(.primary)
            Spacer()
            Text(formatTemp(day.temperature, unit: day.temperatureUnit))
              .font(.subheadline)
              .fontWeight(.medium)
          }
          .padding(.vertical, 10)
          if index < (viewModel.snapshot?.daily.count ?? 0) - 1 {
            Divider().opacity(0.35)
          }
        }
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 10)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius: 20, style: .continuous)
          .stroke(
            LinearGradient(
              colors: [
                .white.opacity(0.40),
                .white.opacity(0.08)
              ],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            ),
            lineWidth: 1
          )
      )
      .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 6)
    }
  }

  private var footerAttribution: some View {
    HStack {
      Spacer()
      Text("Data provided by National Weather Service (NWS)")
        .font(.caption2)
        .foregroundStyle(.secondary)
      Spacer()
    }
    .padding(.top, 6)
  }

  private var effectType: WeatherEffect {
    let text = (viewModel.snapshot?.current?.shortForecast ?? "").lowercased()
    if text.contains("thunder") { return .thunder }
    if text.contains("snow") || text.contains("sleet") { return .snow }
    if text.contains("rain") || text.contains("showers") { return .rain }
    if text.contains("fog") || text.contains("mist") { return .fog }
    if text.contains("cloud") || text.contains("overcast") { return .cloudy }
    if text.contains("sunny") || text.contains("clear") || text.contains("fair") { return .clear }
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
