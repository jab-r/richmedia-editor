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
    var isPlaying: Bool = false
    var isEditing: Bool = true
    var isTextEditingLayerId: UUID? = nil
    var onTextChange: ((UUID, String) -> Void)? = nil
    var onBackgroundTap: (() -> Void)? = nil
    var onMediaTransformUpdate: ((MediaTransform) -> Void)? = nil
    var localImage: UIImage? = nil
    var onLayerDelete: ((UUID) -> Void)? = nil
    var onLayerLongPress: ((UUID) -> Void)? = nil

    @State private var player: AVPlayer?

    // Media transform gesture state
    @State private var mediaScale: CGFloat
    @State private var mediaOffset: CGSize
    @State private var gestureStartScale: CGFloat = 1.0
    @State private var gestureStartOffset: CGSize = .zero

    init(
        block: RichPostBlock,
        selectedLayerId: Binding<UUID?>,
        onLayerTap: @escaping (UUID) -> Void,
        onLayerUpdate: @escaping (UUID, LayerPosition) -> Void,
        isPlaying: Bool = false,
        isEditing: Bool = true,
        isTextEditingLayerId: UUID? = nil,
        onTextChange: ((UUID, String) -> Void)? = nil,
        onBackgroundTap: (() -> Void)? = nil,
        onMediaTransformUpdate: ((MediaTransform) -> Void)? = nil,
        localImage: UIImage? = nil,
        onLayerDelete: ((UUID) -> Void)? = nil,
        onLayerLongPress: ((UUID) -> Void)? = nil
    ) {
        self.block = block
        self._selectedLayerId = selectedLayerId
        self.onLayerTap = onLayerTap
        self.onLayerUpdate = onLayerUpdate
        self.isPlaying = isPlaying
        self.isEditing = isEditing
        self.isTextEditingLayerId = isTextEditingLayerId
        self.onTextChange = onTextChange
        self.onBackgroundTap = onBackgroundTap
        self.onMediaTransformUpdate = onMediaTransformUpdate
        self.localImage = localImage
        self.onLayerDelete = onLayerDelete
        self.onLayerLongPress = onLayerLongPress

        let transform = block.mediaTransform ?? MediaTransform()
        _mediaScale = State(initialValue: transform.scale)
        _mediaOffset = State(initialValue: CGSize(
            width: transform.offsetX,
            height: transform.offsetY
        ))
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background media with transform
                mediaContent
                    .scaleEffect(mediaScale)
                    .offset(mediaOffset)

                // Gesture layer for media pan/zoom + background tap
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onBackgroundTap?()
                    }
                    .gesture(mediaDragGesture(canvasSize: geometry.size))
                    .gesture(mediaPinchGesture(canvasSize: geometry.size))

                // Lottie overlay (if present)
                if let lottie = block.lottieOverlay {
                    LottieOverlayView(animation: lottie, play: isPlaying)
                }

                // Text layer overlays
                ForEach(block.textLayers ?? []) { layer in
                    if layer.visible {
                        TextLayerOverlay(
                            layer: layer,
                            canvasSize: geometry.size,
                            isSelected: selectedLayerId == layer.id,
                            isEditing: isEditing,
                            isTextEditing: isTextEditingLayerId == layer.id,
                            onTap: { onLayerTap(layer.id) },
                            onPositionUpdate: { newPosition in
                                onLayerUpdate(layer.id, newPosition)
                            },
                            onTextChange: { newText in
                                onTextChange?(layer.id, newText)
                            },
                            onDelete: {
                                onLayerDelete?(layer.id)
                            },
                            onLongPress: {
                                onLayerLongPress?(layer.id)
                            }
                        )
                    }
                }
            }
            .clipped()
        }
        .aspectRatio(9/16, contentMode: .fit)
        .background(Color.black)
        .cornerRadius(12)
        .onDisappear {
            player?.pause()
            player = nil
        }
    }

    // MARK: - Media Content

    @ViewBuilder
    private var mediaContent: some View {
        if let uiImage = localImage {
            localImageBackground(image: uiImage)
        } else if block.video != nil, let urlString = block.url, let url = URL(string: urlString) {
            videoBackground(url: url)
        } else if block.image != nil, let urlString = block.url, let url = URL(string: urlString) {
            imageBackground(url: url)
        } else {
            placeholderBackground
        }
    }

    // MARK: - Media Gestures

    private func mediaDragGesture(canvasSize: CGSize) -> some Gesture {
        DragGesture()
            .onChanged { value in
                if value.translation == .zero {
                    gestureStartOffset = mediaOffset
                }
                mediaOffset = CGSize(
                    width: gestureStartOffset.width + value.translation.width,
                    height: gestureStartOffset.height + value.translation.height
                )
            }
            .onEnded { value in
                mediaOffset = clampedOffset(
                    CGSize(
                        width: gestureStartOffset.width + value.translation.width,
                        height: gestureStartOffset.height + value.translation.height
                    ),
                    scale: mediaScale,
                    canvasSize: canvasSize
                )
                commitMediaTransform()
            }
    }

    private func mediaPinchGesture(canvasSize: CGSize) -> some Gesture {
        MagnificationGesture()
            .onChanged { value in
                if gestureStartScale == 1.0 && mediaScale != 1.0 {
                    gestureStartScale = mediaScale
                } else if gestureStartScale == 1.0 {
                    gestureStartScale = mediaScale
                }
                mediaScale = max(1.0, gestureStartScale * value)
            }
            .onEnded { value in
                let newScale = max(1.0, min(5.0, gestureStartScale * value))
                mediaScale = newScale
                mediaOffset = clampedOffset(mediaOffset, scale: newScale, canvasSize: canvasSize)
                gestureStartScale = newScale
                commitMediaTransform()
            }
    }

    private func clampedOffset(_ offset: CGSize, scale: CGFloat, canvasSize: CGSize) -> CGSize {
        // Allow panning only as far as the scaled media edge reaches the canvas edge
        let maxOffsetX = canvasSize.width * (scale - 1) / 2
        let maxOffsetY = canvasSize.height * (scale - 1) / 2
        return CGSize(
            width: max(-maxOffsetX, min(maxOffsetX, offset.width)),
            height: max(-maxOffsetY, min(maxOffsetY, offset.height))
        )
    }

    private func commitMediaTransform() {
        let transform = MediaTransform(
            scale: mediaScale,
            offsetX: mediaOffset.width,
            offsetY: mediaOffset.height
        )
        onMediaTransformUpdate?(transform)
    }

    // MARK: - Media Backgrounds

    @ViewBuilder
    private func localImageBackground(image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
    }

    @ViewBuilder
    private func imageBackground(url: URL) -> some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
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
            .disabled(true)
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
        newPlayer.isMuted = true
        player = newPlayer
        return newPlayer
    }
}

/// Draggable, rotatable, scalable text overlay with inline editing
struct TextLayerOverlay: View {
    let layer: TextLayer
    let canvasSize: CGSize
    let isSelected: Bool
    let isEditing: Bool
    let isTextEditing: Bool
    let onTap: () -> Void
    let onPositionUpdate: (LayerPosition) -> Void
    let onTextChange: (String) -> Void
    var onDelete: (() -> Void)? = nil
    var onLongPress: (() -> Void)? = nil

    @State private var currentPosition: CGPoint
    @State private var currentScale: CGFloat
    @State private var currentRotation: Angle
    @State private var editableText: String
    @FocusState private var isFieldFocused: Bool

    init(
        layer: TextLayer,
        canvasSize: CGSize,
        isSelected: Bool,
        isEditing: Bool,
        isTextEditing: Bool,
        onTap: @escaping () -> Void,
        onPositionUpdate: @escaping (LayerPosition) -> Void,
        onTextChange: @escaping (String) -> Void,
        onDelete: (() -> Void)? = nil,
        onLongPress: (() -> Void)? = nil
    ) {
        self.layer = layer
        self.canvasSize = canvasSize
        self.isSelected = isSelected
        self.isEditing = isEditing
        self.isTextEditing = isTextEditing
        self.onTap = onTap
        self.onPositionUpdate = onPositionUpdate
        self.onTextChange = onTextChange
        self.onDelete = onDelete
        self.onLongPress = onLongPress

        _currentPosition = State(initialValue: CGPoint(
            x: layer.position.x * canvasSize.width,
            y: layer.position.y * canvasSize.height
        ))
        _currentScale = State(initialValue: layer.position.scale)
        _currentRotation = State(initialValue: Angle(degrees: layer.position.rotation))
        _editableText = State(initialValue: layer.text)
    }

    var body: some View {
        let styledContent = textContent
            .scaleEffect(currentScale)
            .rotationEffect(currentRotation)
            .position(currentPosition)

        Group {
            if isEditing {
                styledContent
                    .overlay(selectionBorder)
                    .gesture(isTextEditing ? nil : dragGesture)
                    .gesture(isTextEditing ? nil : magnificationGesture)
                    .gesture(isTextEditing ? nil : rotationGesture)
                    .onTapGesture(perform: onTap)
                    .onLongPressGesture {
                        onLongPress?()
                    }
            } else {
                AnimationRenderer.animated(layer: layer, content: textContent)
                    .scaleEffect(currentScale)
                    .rotationEffect(currentRotation)
                    .position(currentPosition)
            }
        }
        .onChange(of: isTextEditing) { editing in
            if editing {
                editableText = layer.text
                isFieldFocused = true
            } else {
                isFieldFocused = false
                // Delete layer if text is empty when editing ends
                if editableText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    onDelete?()
                }
            }
        }
        .onChange(of: editableText) { newValue in
            if isTextEditing {
                onTextChange(newValue)
            }
        }
    }

    @ViewBuilder
    private var textContent: some View {
        if isTextEditing {
            TextField("", text: $editableText, axis: .vertical)
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
                .focused($isFieldFocused)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: canvasSize.width * 0.8)
        } else {
            Text(layer.text)
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
        }
    }

    @ViewBuilder
    private var selectionBorder: some View {
        if isSelected {
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.blue, lineWidth: 2)
                .padding(-8)
        }
    }

    // MARK: - Gestures

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                currentPosition = value.location
            }
            .onEnded { value in
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

    private func alignmentForStyle(_ style: TextLayerStyle) -> SwiftUI.TextAlignment {
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
