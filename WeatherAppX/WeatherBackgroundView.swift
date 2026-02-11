import SwiftUI

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

  var body: some View {
    ZStack {
      backgroundGradient
      TimelineView(.animation) { timeline in
        Canvas { context, size in
          let dt = timeline.date.timeIntervalSince(lastTime)
          lastTime = timeline.date
          updateParticles(size: size, dt: dt)
          draw(context: context, size: size)
        }
      }
    }
    .ignoresSafeArea()
    .onAppear { resetParticles() }
    .onChange(of: effect) { _ in resetParticles() }
  }

  private var backgroundGradient: some View {
    let colors: [Color]
    switch effect {
    case .snow: colors = [Color(red: 0.8, green: 0.9, blue: 1.0), Color(red: 0.1, green: 0.2, blue: 0.3)]
    case .rain: colors = [Color(red: 0.4, green: 0.5, blue: 0.7), Color(red: 0.07, green: 0.12, blue: 0.18)]
    case .thunder: colors = [Color(red: 0.3, green: 0.35, blue: 0.5), Color(red: 0.05, green: 0.07, blue: 0.1)]
    case .fog: colors = [Color(red: 0.7, green: 0.75, blue: 0.8), Color(red: 0.2, green: 0.25, blue: 0.3)]
    case .cloudy: colors = [Color(red: 0.55, green: 0.62, blue: 0.7), Color(red: 0.14, green: 0.2, blue: 0.28)]
    case .clear: colors = [Color(red: 0.15, green: 0.25, blue: 0.36), Color(red: 0.06, green: 0.1, blue: 0.17)]
    }
    return LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
  }

  private func resetParticles() {
    particles.removeAll()
    let count: Int
    switch effect {
    case .snow: count = 120
    case .rain, .thunder: count = 120
    case .cloudy, .fog: count = 40
    case .clear: count = 0
    }
    for _ in 0..<count {
      particles.append(Particle(effect: effect))
    }
  }

  private func updateParticles(size: CGSize, dt: TimeInterval) {
    guard !particles.isEmpty else { return }
    let delta = CGFloat(min(dt, 0.05))
    wind = wind * 0.96 + CGFloat.random(in: -10...10) * 0.04

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
      particle.draw(in: &context)
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
    self.size = CGFloat.random(in: 1.5...4)
    self.depth = CGFloat.random(in: 0.3...1)
    self.sway = CGFloat.random(in: 0...Double.pi * 2)
    self.rotation = CGFloat.random(in: 0...Double.pi * 2)
  }

  mutating func update(size: CGSize, delta: CGFloat, wind: CGFloat) {
    switch kind {
    case .rain, .thunder:
      velocity.y = 300 + depth * 200
      position.y += velocity.y * delta
      position.x += (wind + 20) * delta
      if position.y > size.height { position.y = -10; position.x = CGFloat.random(in: 0...size.width) }
    case .snow:
      velocity.y = 40 + depth * 40
      position.y += velocity.y * delta
      position.x += (wind * 0.3 + sin(sway) * 12 * depth) * delta
      sway += delta * (0.6 + depth)
      rotation += delta * 0.6
      if position.y > size.height { position.y = -10; position.x = CGFloat.random(in: 0...size.width) }
    case .cloudy, .fog:
      velocity.x = 8 + depth * 8
      position.x += velocity.x * delta
      if position.x > size.width + 80 { position.x = -80; position.y = CGFloat.random(in: 0...size.height * 0.6) }
    case .clear:
      break
    }
  }

  func draw(in context: inout GraphicsContext) {
    switch kind {
    case .rain, .thunder:
      var path = Path()
      path.move(to: position)
      path.addLine(to: CGPoint(x: position.x + 2, y: position.y + size * 6))
      context.stroke(path, with: .color(.white.opacity(0.45)), lineWidth: 1)
    case .snow:
      var contextCopy = context
      contextCopy.opacity = 0.25 + Double(depth) * 0.65
      contextCopy.addFilter(.blur(radius: Double((1 - depth) * 1.8)))
      contextCopy.translateBy(x: position.x, y: position.y)
      contextCopy.rotate(by: .radians(Double(rotation)))

      let arm = size * 2.4
      for i in 0..<6 {
        let angle = Double(i) * Double.pi / 3
        var path = Path()
        path.move(to: .zero)
        path.addLine(to: CGPoint(x: cos(angle) * arm, y: sin(angle) * arm))
        path.addLine(to: CGPoint(x: cos(angle) * arm * 0.7 - sin(angle) * arm * 0.2, y: sin(angle) * arm * 0.7 + cos(angle) * arm * 0.2))
        path.move(to: CGPoint(x: cos(angle) * arm * 0.7, y: sin(angle) * arm * 0.7))
        path.addLine(to: CGPoint(x: cos(angle) * arm * 0.7 + sin(angle) * arm * 0.2, y: sin(angle) * arm * 0.7 - cos(angle) * arm * 0.2))
        contextCopy.stroke(path, with: .color(.white), lineWidth: max(0.5, size * 0.28))
      }
    case .cloudy, .fog:
      let opacity = kind == .fog ? 0.25 : 0.15
      var cloud = Path(ellipseIn: CGRect(x: position.x, y: position.y, width: size * 18, height: size * 10))
      context.fill(cloud, with: .color(.white.opacity(opacity)))
    case .clear:
      break
    }
  }
}

#Preview {
  WeatherBackgroundView(effect: .snow)
}
