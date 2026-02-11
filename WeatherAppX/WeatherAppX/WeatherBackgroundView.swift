import SwiftUI
import Combine

enum WeatherEffect {
  case clear
  case rain
  case snow
  case thunder
  case cloudy
  case fog
}

struct WeatherBackgroundView: View {
  let effect: WeatherEffect

  @State private var particles: [Particle] = []
  @State private var lastTime: Date = .now
  @State private var wind: CGFloat = 0
  @State private var lightning: CGFloat = 0
  @State private var lastSize: CGSize? = nil
  @State private var timer = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common).autoconnect()

  var body: some View {
    ZStack {
      backgroundGradient
      sunGlow
      Canvas { context, size in
        draw(context: context, size: size)
      }
    }
    .ignoresSafeArea()
    .background(
      GeometryReader { proxy in
        Color.clear
          .onAppear { lastSize = proxy.size }
          .onChange(of: proxy.size) { _, newSize in lastSize = newSize }
      }
    )
    .onReceive(timer) { now in
      DispatchQueue.main.async {
        let dt = now.timeIntervalSince(lastTime)
        lastTime = now
        updateParticles(size: lastSize ?? .zero, dt: dt)
      }
    }
    .onAppear { resetParticles() }
    .onChange(of: effect) { _, _ in resetParticles() }
  }

  private var backgroundGradient: some View {
    let colors: [Color]
    switch effect {
    case .snow: colors = [Color(red: 0.78, green: 0.86, blue: 0.95), Color(red: 0.18, green: 0.26, blue: 0.36)]
    case .rain: colors = [Color(red: 0.36, green: 0.48, blue: 0.66), Color(red: 0.08, green: 0.12, blue: 0.19)]
    case .thunder: colors = [Color(red: 0.30, green: 0.34, blue: 0.50), Color(red: 0.05, green: 0.07, blue: 0.11)]
    case .fog: colors = [Color(red: 0.72, green: 0.78, blue: 0.84), Color(red: 0.22, green: 0.28, blue: 0.34)]
    case .cloudy: colors = [Color(red: 0.58, green: 0.66, blue: 0.74), Color(red: 0.18, green: 0.24, blue: 0.32)]
    case .clear: colors = [Color(red: 0.44, green: 0.70, blue: 0.92), Color(red: 0.15, green: 0.30, blue: 0.55)]
    }
    return LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
  }

  private var sunGlow: some View {
    guard effect == .clear else { return AnyView(EmptyView()) }
    return AnyView(
      ZStack {
        RadialGradient(
          colors: [
            Color(red: 1.0, green: 0.88, blue: 0.55).opacity(0.55),
            Color(red: 1.0, green: 0.88, blue: 0.55).opacity(0.18),
            Color.clear
          ],
          center: .topTrailing,
          startRadius: 10,
          endRadius: 260
        )
        .blendMode(.screen)

        RadialGradient(
          colors: [
            Color(red: 1.0, green: 0.72, blue: 0.45).opacity(0.18),
            Color.clear
          ],
          center: .topTrailing,
          startRadius: 120,
          endRadius: 420
        )
        .blendMode(.plusLighter)
      }
      .ignoresSafeArea()
    )
  }

  private func resetParticles() {
    particles.removeAll()
    let count: Int
    switch effect {
    case .snow: count = 90
    case .rain, .thunder: count = 90
    case .cloudy: count = 14
    case .fog: count = 18
    case .clear: count = 14
    }
    for _ in 0..<count {
      particles.append(Particle(effect: effect))
    }
  }

  private func updateParticles(size: CGSize, dt: TimeInterval) {
    lastSize = size
    guard !particles.isEmpty else { return }
    let delta = CGFloat(min(dt, 0.05))
    wind = wind * 0.97 + CGFloat.random(in: -8...8) * 0.03

    for idx in particles.indices {
      particles[idx].update(size: size, delta: delta, wind: wind)
    }

    if effect == .thunder {
      if Bool.random() && lightning <= 0 {
        lightning = CGFloat.random(in: 0.5...0.9)
      }
      lightning = max(0, lightning - delta * 1.8)
    } else {
      lightning = 0
    }
  }

  private func draw(context: GraphicsContext, size: CGSize) {
    if effect == .thunder && lightning > 0 {
      context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.white.opacity(Double(lightning))))
    }

    for particle in particles {
      particle.draw(in: context)
    }
  }
}

struct Particle {
  var position: CGPoint
  var velocity: CGPoint
  var size: CGFloat
  var depth: CGFloat
  var sway: CGFloat
  var rotation: CGFloat
  var kind: WeatherEffect

  init(effect: WeatherEffect) {
    self.kind = effect
    self.position = CGPoint(x: CGFloat.random(in: 0...320), y: CGFloat.random(in: 0...600))
    self.velocity = CGPoint(x: CGFloat.random(in: -10...10), y: CGFloat.random(in: 20...120))
    switch effect {
    case .cloudy, .fog:
      self.size = CGFloat.random(in: 6...12)
    case .snow:
      self.size = CGFloat.random(in: 1.4...3.2)
    case .clear:
      self.size = CGFloat.random(in: 10...18)
    default:
      self.size = CGFloat.random(in: 1.2...3.2)
    }
    self.depth = CGFloat.random(in: 0.3...1)
    self.sway = CGFloat.random(in: 0...Double.pi * 2)
    self.rotation = CGFloat.random(in: 0...Double.pi * 2)
  }

  mutating func update(size: CGSize, delta: CGFloat, wind: CGFloat) {
    switch kind {
    case .rain, .thunder:
      velocity.y = 240 + depth * 160
      position.y += velocity.y * delta
      position.x += (wind + 20) * delta
      if position.y > size.height { position.y = -10; position.x = CGFloat.random(in: 0...size.width) }
    case .snow:
      velocity.y = 28 + depth * 34
      position.y += velocity.y * delta
      position.x += (wind * 0.3 + sin(sway) * 12 * depth) * delta
      sway += delta * (0.6 + depth)
      rotation += delta * 0.6
      if position.y > size.height { position.y = -10; position.x = CGFloat.random(in: 0...size.width) }
    case .cloudy, .fog:
      velocity.x = 3 + depth * 4
      position.x += velocity.x * delta
      if position.x > size.width + 160 { position.x = -160; position.y = CGFloat.random(in: 0...size.height * 0.6) }
    case .clear:
      // Clear days: barely-moving light bokeh, just enough to feel alive.
      velocity.x = 6 + depth * 10
      velocity.y = 3 + depth * 6
      position.x += (velocity.x + wind * 0.2) * delta
      position.y += velocity.y * delta
      sway += delta * (0.25 + depth * 0.2)
      if position.x > size.width + 80 { position.x = -80; position.y = CGFloat.random(in: 0...size.height * 0.7) }
      if position.y > size.height + 60 { position.y = -60; position.x = CGFloat.random(in: 0...size.width) }
    }
  }

  func draw(in context: GraphicsContext) {
    switch kind {
    case .rain, .thunder:
      var path = Path()
      path.move(to: position)
      path.addLine(to: CGPoint(x: position.x + 1.6, y: position.y + size * 5.2))
      context.stroke(path, with: .color(.white.opacity(0.35)), lineWidth: 0.9)
    case .snow:
      var contextCopy = context
      contextCopy.opacity = 0.2 + Double(depth) * 0.6
      contextCopy.addFilter(.blur(radius: Double((1 - depth) * 1.5)))
      contextCopy.translateBy(x: position.x, y: position.y)
      contextCopy.rotate(by: .radians(Double(rotation)))

      let arm = size * 2.1
      for i in 0..<6 {
        let angle = Double(i) * Double.pi / 3
        let ca = CGFloat(Darwin.cos(angle))
        let sa = CGFloat(Darwin.sin(angle))
        var path = Path()
        path.move(to: .zero)
        path.addLine(to: CGPoint(x: ca * arm, y: sa * arm))
        path.addLine(to: CGPoint(x: ca * arm * 0.7 - sa * arm * 0.2, y: sa * arm * 0.7 + ca * arm * 0.2))
        path.move(to: CGPoint(x: ca * arm * 0.7, y: sa * arm * 0.7))
        path.addLine(to: CGPoint(x: ca * arm * 0.7 + sa * arm * 0.2, y: sa * arm * 0.7 - ca * arm * 0.2))
        contextCopy.stroke(path, with: .color(.white), lineWidth: max(0.45, size * 0.26))
      }
    case .cloudy, .fog:
      var contextCopy = context
      let opacity = kind == .fog ? 0.18 : 0.12
      let blur = kind == .fog ? 10.0 : 6.0
      contextCopy.opacity = opacity + Double(depth) * 0.12
      contextCopy.addFilter(.blur(radius: blur))

      let baseW = size * 22
      let baseH = size * 9
      let x = position.x
      let y = position.y

      var cloud = Path()
      cloud.addEllipse(in: CGRect(x: x, y: y + baseH * 0.2, width: baseW * 0.45, height: baseH))
      cloud.addEllipse(in: CGRect(x: x + baseW * 0.2, y: y, width: baseW * 0.55, height: baseH * 1.2))
      cloud.addEllipse(in: CGRect(x: x + baseW * 0.5, y: y + baseH * 0.15, width: baseW * 0.5, height: baseH))
      cloud.addRect(CGRect(x: x + baseW * 0.1, y: y + baseH * 0.6, width: baseW * 0.8, height: baseH * 0.6))

      contextCopy.fill(cloud, with: .color(.white))
    case .clear:
      var contextCopy = context
      let drift = (sin(sway) * 6) * depth
      let r = size * (1.6 + depth * 1.8)
      let alpha = 0.03 + Double(depth) * 0.05
      contextCopy.opacity = alpha
      contextCopy.addFilter(.blur(radius: Double(6 + (1 - depth) * 8)))
      let circle = Path(ellipseIn: CGRect(x: position.x + drift, y: position.y, width: r * 2, height: r * 2))
      contextCopy.fill(circle, with: .color(.white))
    }
  }
}

#Preview {
  WeatherBackgroundView(effect: .snow)
}
