import SwiftUI
import AVKit

/// Fullscreen looping video view for onboarding / loading screens.
struct VideoLoopView: View {
  let resourceName: String
  let resourceExtension: String

  @State private var player: AVPlayer? = nil

  var body: some View {
    Group {
      if let player {
        VideoPlayer(player: player)
          .ignoresSafeArea()
          .onAppear {
            player.play()
          }
          .onDisappear {
            player.pause()
          }
      } else {
        Color.black.ignoresSafeArea()
      }
    }
    .allowsHitTesting(false)
    .task {
      if player == nil {
        player = makeLoopingPlayer()
      }
    }
  }

  private func makeLoopingPlayer() -> AVPlayer? {
    guard let url = Bundle.main.url(forResource: resourceName, withExtension: resourceExtension) else {
      return nil
    }

    let item = AVPlayerItem(url: url)
    let player = AVPlayer(playerItem: item)
    player.isMuted = true
    player.actionAtItemEnd = .none

    NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: .main) { _ in
      item.seek(to: .zero, completionHandler: nil)
      player.play()
    }

    return player
  }
}

#Preview {
  VideoLoopView(resourceName: "STG_pow-2", resourceExtension: "mp4")
}

