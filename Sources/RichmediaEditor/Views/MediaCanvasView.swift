//
// MediaCanvasView.swift
// RichmediaEditor
//
// Displays media (image/video) with draggable text layer overlays
//

import SwiftUI
import AVKit

#if canImport(UIKit)

struct MediaCanvasView: View {
    let block: RichPostBlock
    @Binding var selectedLayerId: UUID?
    let onLayerTap: (UUID) -> Void
    let onLayerUpdate: (UUID, LayerPosition) -> Void

    @State private var player: AVPlayer?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background media
                if block.video != nil, let urlString = block.url, let url = URL(string: urlString) {
                    videoBackground(url: url)
                } else if block.image != nil, let urlString = block.url, let url = URL(string: urlString) {
                    imageBackground(url: url)
                } else {
                    placeholderBackground
                }

                // Text layer overlays
                ForEach(block.textLayers ?? []) { layer in
                    if layer.visible {
                        TextLayerOverlay(
                            layer: layer,
                            canvasSize: geometry.size,
                            isSelected: selectedLayerId == layer.id,
                            onTap: { onLayerTap(layer.id) },
                            onPositionUpdate: { newPosition in
                                onLayerUpdate(layer.id, newPosition)
                            }
                        )
                    }
                }
            }
        }
        .aspectRatio(9/16, contentMode: .fit)
        .background(Color.black)
        .cornerRadius(12)
        .onDisappear {
            player?.pause()
            player = nil
        }
    }

    @ViewBuilder
    private func imageBackground(url: URL) -> some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFit()
            case .failure:
                placeholderBackground
            case .empty:
                ProgressView()
            @unknown default:
                EmptyView()
            }
        }
    }

    @ViewBuilder
    private func videoBackground(url: URL) -> some View {
        VideoPlayer(player: getOrCreatePlayer(url: url))
            .disabled(true)  // Disable controls during editing
    }

    private var placeholderBackground: some View {
        Rectangle()
            .fill(Color(.systemGray5))
            .overlay(
                Image(systemName: "photo")
                    .font(.system(size: 60))
                    .foregroundColor(.secondary)
            )
    }

    private func getOrCreatePlayer(url: URL) -> AVPlayer {
        if let existing = player {
            return existing
        }
        let newPlayer = AVPlayer(url: url)
        newPlayer.isMuted = true  // Muted during editing
        player = newPlayer
        return newPlayer
    }
}

/// Draggable, rotatable, scalable text overlay
struct TextLayerOverlay: View {
    let layer: TextLayer
    let canvasSize: CGSize
    let isSelected: Bool
    let onTap: () -> Void
    let onPositionUpdate: (LayerPosition) -> Void

    @State private var currentPosition: CGPoint
    @State private var currentScale: CGFloat
    @State private var currentRotation: Angle

    init(layer: TextLayer, canvasSize: CGSize, isSelected: Bool, onTap: @escaping () -> Void, onPositionUpdate: @escaping (LayerPosition) -> Void) {
        self.layer = layer
        self.canvasSize = canvasSize
        self.isSelected = isSelected
        self.onTap = onTap
        self.onPositionUpdate = onPositionUpdate

        // Initialize state from layer
        _currentPosition = State(initialValue: CGPoint(
            x: layer.position.x * canvasSize.width,
            y: layer.position.y * canvasSize.height
        ))
        _currentScale = State(initialValue: layer.position.scale)
        _currentRotation = State(initialValue: Angle(degrees: layer.position.rotation))
    }

    var body: some View {
        let baseText = Text(layer.text)
            .font(fontForStyle(layer.style))
            .foregroundColor(Color(hex: layer.style.color))
            .bold(layer.style.bold)
            .italic(layer.style.italic)
            .underline(layer.style.underline)
            .multilineTextAlignment(alignmentForStyle(layer.style))
            .shadow(
                color: shadowColor,
                radius: layer.style.shadow?.radius ?? 0,
                x: layer.style.shadow?.offset.width ?? 0,
                y: layer.style.shadow?.offset.height ?? 0
            )

        let animatedText = AnimationRenderer.animated(layer: layer, content: baseText)

        animatedText
            .scaleEffect(currentScale)
            .rotationEffect(currentRotation)
            .position(currentPosition)
            .overlay(
                // Selection border
                isSelected ?
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.blue, lineWidth: 2)
                        .padding(-8)
                    : nil
            )
            .gesture(dragGesture)
            .gesture(magnificationGesture)
            .gesture(rotationGesture)
            .onTapGesture(perform: onTap)
    }

    // MARK: - Gestures

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                currentPosition = value.location
            }
            .onEnded { value in
                // Convert to percentage
                let newX = value.location.x / canvasSize.width
                let newY = value.location.y / canvasSize.height

                var updatedPosition = layer.position
                updatedPosition.x = max(0, min(1, newX))
                updatedPosition.y = max(0, min(1, newY))

                onPositionUpdate(updatedPosition)
            }
    }

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                currentScale = layer.position.scale * value
            }
            .onEnded { value in
                var updatedPosition = layer.position
                updatedPosition.scale = max(0.5, min(3.0, layer.position.scale * value))
                onPositionUpdate(updatedPosition)
            }
    }

    private var rotationGesture: some Gesture {
        RotationGesture()
            .onChanged { value in
                currentRotation = Angle(degrees: layer.position.rotation) + value
            }
            .onEnded { value in
                var updatedPosition = layer.position
                updatedPosition.rotation = (layer.position.rotation + value.degrees).truncatingRemainder(dividingBy: 360)
                onPositionUpdate(updatedPosition)
            }
    }

    // MARK: - Helpers

    private func fontForStyle(_ style: TextLayerStyle) -> Font {
        let size = style.size
        switch style.font {
        case "Georgia":
            return .custom("Georgia", size: size)
        case "Helvetica":
            return .custom("Helvetica", size: size)
        case "Courier":
            return .custom("Courier", size: size)
        case "Times New Roman":
            return .custom("Times New Roman", size: size)
        default:
            return .system(size: size)
        }
    }

    private func alignmentForStyle(_ style: TextLayerStyle) -> TextAlignment {
        switch style.align {
        case .left: return .leading
        case .center: return .center
        case .right: return .trailing
        }
    }

    private var shadowColor: Color {
        guard let shadow = layer.style.shadow else { return .clear }
        return Color(hex: shadow.color).opacity(shadow.opacity)
    }
}

#endif
