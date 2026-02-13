//
// LottieOverlayView.swift
// RichmediaEditor
//
// SwiftUI wrapper for Lottie animation rendering
//

import SwiftUI
import Lottie

#if canImport(UIKit)
import UIKit

/// SwiftUI wrapper for Lottie animations
struct LottieOverlayView: UIViewRepresentable {
    let animation: LottieAnimation
    let play: Bool

    func makeUIView(context: Context) -> LottieAnimationView {
        let animationView = LottieAnimationView()
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = animation.loops ? .loop : .playOnce
        animationView.backgroundBehavior = .pauseAndRestore

        // Load animation from JSON data
        if let data = animation.jsonData.data(using: .utf8),
           let lottieAnimation = try? JSONDecoder().decode(Lottie.LottieAnimation.self, from: data) {
            animationView.animation = lottieAnimation
        }

        return animationView
    }

    func updateUIView(_ uiView: LottieAnimationView, context: Context) {
        if play {
            if !uiView.isAnimationPlaying {
                uiView.play()
            }
        } else {
            if uiView.isAnimationPlaying {
                uiView.pause()
            }
        }
    }
}

/// Configurable Lottie view with playback controls
public struct LottiePlayerView: View {
    let animation: LottieAnimation
    @State private var isPlaying = false

    public init(animation: LottieAnimation) {
        self.animation = animation
    }

    public var body: some View {
        VStack {
            LottieOverlayView(animation: animation, play: isPlaying)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Playback controls
            HStack(spacing: 20) {
                Button(action: {
                    isPlaying.toggle()
                }) {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.title)
                        .foregroundStyle(.blue.gradient)
                }

                Text(animation.name)
                    .font(.subheadline)

                Spacer()

                Text(String(format: "%.1fs", animation.duration))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(.ultraThinMaterial)
        }
    }
}

#endif
