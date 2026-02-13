//
// GalleryPlayerView.swift
// RichmediaEditor
//
// TikTok-style gallery player for viewing animated posts
//

import SwiftUI

#if canImport(UIKit)

/// Full-screen gallery player for viewing animated posts (TikTok style)
public struct GalleryPlayerView: View {
    let content: RichPostContent
    @Environment(\.dismiss) private var dismiss

    @State private var currentPage = 0
    @State private var isPlaying = true

    public init(content: RichPostContent) {
        self.content = content
    }

    public var body: some View {
        ZStack {
            // Black background
            Color.black.ignoresSafeArea()

            // Gallery
            TabView(selection: $currentPage) {
                ForEach(Array(content.blocks.enumerated()), id: \.element.id) { index, block in
                    pageView(for: block)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // Overlay controls
            VStack {
                // Top bar
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 2)
                    }

                    Spacer()

                    // Page indicator
                    if content.blocks.count > 1 {
                        HStack(spacing: 4) {
                            ForEach(0..<content.blocks.count, id: \.self) { index in
                                Capsule()
                                    .fill(index == currentPage ? Color.white : Color.white.opacity(0.4))
                                    .frame(width: index == currentPage ? 24 : 8, height: 4)
                                    .animation(.spring(response: 0.3), value: currentPage)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                    }

                    Spacer()

                    // Play/pause
                    Button(action: {
                        isPlaying.toggle()
                    }) {
                        Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 2)
                    }
                }
                .padding()

                Spacer()

                // Bottom info
                if content.blocks.indices.contains(currentPage) {
                    let block = content.blocks[currentPage]
                    if let caption = block.caption, !caption.isEmpty {
                        HStack {
                            Text(caption)
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.leading)
                                .shadow(color: .black.opacity(0.5), radius: 2)

                            Spacer()
                        }
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.clear, .black.opacity(0.6)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func pageView(for block: RichPostBlock) -> some View {
        GeometryReader { geometry in
            ZStack {
                // Background media
                if let urlString = block.url, let url = URL(string: urlString) {
                    if block.video != nil {
                        // Video background
                        Color.black
                            .overlay(
                                Text("Video: \(urlString)")
                                    .foregroundColor(.white)
                            )
                    } else {
                        // Image background
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFit()
                        } placeholder: {
                            ProgressView()
                        }
                    }
                }

                // Lottie overlay (if present)
                if let lottie = block.lottieOverlay {
                    LottieOverlayView(animation: lottie, play: isPlaying)
                }

                // Animated text layers
                if let textLayers = block.textLayers {
                    ForEach(textLayers.filter { $0.visible }) { layer in
                        animatedTextView(layer: layer, canvasSize: geometry.size)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func animatedTextView(layer: TextLayer, canvasSize: CGSize) -> some View {
        let baseText = Text(layer.text)
            .font(fontForStyle(layer.style))
            .foregroundColor(Color(hex: layer.style.color))
            .bold(layer.style.bold)
            .italic(layer.style.italic)
            .shadow(
                color: shadowColor(for: layer),
                radius: layer.style.shadow?.radius ?? 0,
                x: layer.style.shadow?.offset.width ?? 0,
                y: layer.style.shadow?.offset.height ?? 0
            )

        // Apply animation if playing
        if isPlaying {
            AnimationRenderer.animated(layer: layer, content: baseText)
                .position(
                    x: layer.position.x * canvasSize.width,
                    y: layer.position.y * canvasSize.height
                )
                .scaleEffect(layer.position.scale)
                .rotationEffect(.degrees(layer.position.rotation))
        } else {
            baseText
                .position(
                    x: layer.position.x * canvasSize.width,
                    y: layer.position.y * canvasSize.height
                )
                .scaleEffect(layer.position.scale)
                .rotationEffect(.degrees(layer.position.rotation))
        }
    }

    // MARK: - Helpers

    private func fontForStyle(_ style: TextLayerStyle) -> Font {
        let size = style.size
        switch style.font {
        case "Georgia": return .custom("Georgia", size: size)
        case "Helvetica": return .custom("Helvetica", size: size)
        case "Courier": return .custom("Courier", size: size)
        case "Times New Roman": return .custom("Times New Roman", size: size)
        default: return .system(size: size)
        }
    }

    private func shadowColor(for layer: TextLayer) -> Color {
        guard let shadow = layer.style.shadow else { return .clear }
        return Color(hex: shadow.color).opacity(shadow.opacity)
    }
}

#endif
