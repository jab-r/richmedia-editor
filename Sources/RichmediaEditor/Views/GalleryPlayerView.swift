//
// GalleryPlayerView.swift
// RichmediaEditor
//
// TikTok-style gallery player for viewing animated posts (read-only)
//

import SwiftUI
import AVKit

#if canImport(UIKit)

/// Full-screen gallery player for viewing animated posts (TikTok style)
public struct GalleryPlayerView: View {
    let content: RichPostContent
    var localImages: [UUID: UIImage] = [:]
    @Environment(\.dismiss) private var dismiss

    @State private var currentPage = 0
    @State private var isPlaying = true
    @StateObject private var audioPlayer = PreviewAudioPlayer()

    public init(content: RichPostContent, localImages: [UUID: UIImage] = [:]) {
        self.content = content
        self.localImages = localImages
    }

    public var body: some View {
        ZStack {
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
            VStack(spacing: 0) {
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

                // Bottom caption
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

                // Song title at the very bottom
                if let track = content.musicTrack {
                    HStack(spacing: 6) {
                        Image(systemName: "music.note")
                            .font(.caption)
                        Text("\(track.trackName) — \(track.artistName)")
                            .font(.caption)
                            .lineLimit(1)
                    }
                    .foregroundColor(.white.opacity(0.9))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.black.opacity(0.5))
                }
            }
        }
        .onAppear {
            if let track = content.musicTrack {
                audioPlayer.play(track)
            }
        }
        .onDisappear {
            audioPlayer.stop()
        }
        .onChange(of: isPlaying) { playing in
            if playing {
                if let track = content.musicTrack, audioPlayer.currentTrack == nil {
                    audioPlayer.play(track)
                } else {
                    audioPlayer.resume()
                }
            } else {
                audioPlayer.pause()
            }
        }
    }

    @ViewBuilder
    private func pageView(for block: RichPostBlock) -> some View {
        GeometryReader { geometry in
            ZStack {
                // Background media with transform
                mediaView(for: block)
                    .scaleEffect(block.mediaTransform?.scale ?? 1.0)
                    .offset(CGSize(
                        width: block.mediaTransform?.offsetX ?? 0,
                        height: block.mediaTransform?.offsetY ?? 0
                    ))

                // Lottie overlay
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
            .clipped()
        }
        .aspectRatio(9/16, contentMode: .fit)
    }

    @ViewBuilder
    private func mediaView(for block: RichPostBlock) -> some View {
        if let uiImage = localImages[block.id] {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        } else if block.video != nil, let urlString = block.url, let url = URL(string: urlString) {
            VideoPlayer(player: AVPlayer(url: url))
        } else if block.image != nil, let urlString = block.url, let url = URL(string: urlString) {
            AsyncImage(url: url) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                ProgressView()
            }
        } else {
            Color.black
        }
    }

    @ViewBuilder
    private func animatedTextView(layer: TextLayer, canvasSize: CGSize) -> some View {
        let baseText = Text(layer.text)
            .font(fontForStyle(layer.style))
            .foregroundColor(Color(hex: layer.style.color))
            .bold(layer.style.bold)
            .italic(layer.style.italic)
            .underline(layer.style.underline)
            .multilineTextAlignment(alignmentForStyle(layer.style))
            .shadow(
                color: shadowColor(for: layer),
                radius: layer.style.shadow?.radius ?? 0,
                x: layer.style.shadow?.offset.width ?? 0,
                y: layer.style.shadow?.offset.height ?? 0
            )

        Group {
            if isPlaying {
                AnimationRenderer.animated(layer: layer, content: baseText)
            } else {
                baseText
            }
        }
        .position(
            x: layer.position.x * canvasSize.width,
            y: layer.position.y * canvasSize.height
        )
        .scaleEffect(layer.position.scale)
        .rotationEffect(.degrees(layer.position.rotation))
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

    private func alignmentForStyle(_ style: TextLayerStyle) -> SwiftUI.TextAlignment {
        switch style.align {
        case .left: return .leading
        case .center: return .center
        case .right: return .trailing
        }
    }

    private func shadowColor(for layer: TextLayer) -> Color {
        guard let shadow = layer.style.shadow else { return .clear }
        return Color(hex: shadow.color).opacity(shadow.opacity)
    }
}

#endif
