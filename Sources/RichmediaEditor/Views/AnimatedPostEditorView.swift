//
// AnimatedPostEditorView.swift
// RichmediaEditor
//
// Main public API - Complete animated post editor with glass UI
//

import SwiftUI

#if canImport(UIKit)

public struct AnimatedPostEditorView: View {
    // MARK: - Properties

    let initialMedia: MediaInput?
    let onComplete: (RichPostContent) -> Void
    let onCancel: () -> Void

    @StateObject private var viewModel = AnimatedPostEditorViewModel()
    @State private var showTextEditor = false
    @State private var showPathDrawing = false
    @State private var editingLayer: TextLayer?
    @State private var showMediaTypePicker = false
    @State private var showHelp = false
    @State private var showLottiePicker = false
    @Environment(\.dismiss) private var dismiss

    // MARK: - Initialization

    public init(
        initialMedia: MediaInput? = nil,
        onComplete: @escaping (RichPostContent) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.initialMedia = initialMedia
        self.onComplete = onComplete
        self.onCancel = onCancel
    }

    // MARK: - Body

    public var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(.systemBackground), Color(.systemGray6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                if viewModel.blocks.isEmpty {
                    emptyStateView
                } else {
                    editorContentView
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    onCancel()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark.circle.fill")
                        Text("Cancel")
                    }
                    .foregroundStyle(.secondary)
                }
            }

            ToolbarItem(placement: .principal) {
                Text("Animated Post")
                    .font(.headline)
            }

            ToolbarItem(placement: .primaryAction) {
                Button {
                    handleExport()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Export")
                    }
                    .foregroundStyle(viewModel.validate() ? .blue : .secondary)
                }
                .disabled(!viewModel.validate())
            }
        }
        .sheet(isPresented: $showTextEditor) {
            if let layer = editingLayer,
               let blockId = viewModel.selectedBlockId,
               let blockIndex = viewModel.blocks.firstIndex(where: { $0.id == blockId }),
               let layerIndex = viewModel.blocks[blockIndex].textLayers?.firstIndex(where: { $0.id == layer.id }) {
                TextLayerEditorSheet(
                    layer: Binding(
                        get: { viewModel.blocks[blockIndex].textLayers?[layerIndex] ?? layer },
                        set: { _ in }
                    ),
                    onSave: { updatedLayer in
                        viewModel.updateLayer(updatedLayer.id, in: blockId) { layer in
                            layer.text = updatedLayer.text
                            layer.style = updatedLayer.style
                            layer.animation = updatedLayer.animation
                        }
                    }
                )
            }
        }
        .sheet(isPresented: $showPathDrawing) {
            if let layer = editingLayer,
               let blockId = viewModel.selectedBlockId {
                PathDrawingView(
                    path: Binding(
                        get: { layer.path },
                        set: { _ in }
                    ),
                    onComplete: { path in
                        viewModel.updateLayer(layer.id, in: blockId) { layer in
                            layer.path = path
                            // Set motion path animation if not already set
                            if layer.animation == nil {
                                layer.animation = TextAnimation(preset: .motionPath, duration: 2.0)
                            }
                        }
                    }
                )
            }
        }
        .sheet(isPresented: $showMediaTypePicker) {
            mediaTypePickerView
        }
        .sheet(isPresented: $showHelp) {
            helpView
        }
        .sheet(isPresented: $showLottiePicker) {
            LottiePickerView { lottieAnimation in
                // TODO: Add Lottie overlay to selected block
                if let blockId = viewModel.selectedBlockId ?? viewModel.blocks.first?.id {
                    // For now, create a text layer with Lottie reference
                    // In future: store in block.lottieOverlay
                    viewModel.addTextLayer(to: blockId)
                }
            }
        }
        .onAppear {
            setupInitialMedia()
        }
    }

    // MARK: - Views

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 120, height: 120)

                Image(systemName: "photo.badge.plus")
                    .font(.system(size: 50))
                    .foregroundStyle(.blue.gradient)
            }

            // Text
            VStack(spacing: 8) {
                Text("Create Animated Post")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Add photos or videos with animated text overlays")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            // Action button
            Button(action: {
                showMediaTypePicker = true
            }) {
                Label("Add Media", systemImage: "photo.on.rectangle")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var editorContentView: some View {
        VStack(spacing: 0) {
            // Main canvas area
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(viewModel.blocks) { block in
                        canvasCard(for: block)
                    }
                }
                .padding()
            }

            Divider()

            // Bottom toolbar with glass effect
            editorToolbar
                .background(.ultraThinMaterial)
        }
    }

    @ViewBuilder
    private func canvasCard(for block: RichPostBlock) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Canvas with media + text layers
            MediaCanvasView(
                block: block,
                selectedLayerId: $viewModel.selectedLayerId,
                onLayerTap: { layerId in
                    viewModel.selectLayer(layerId, in: block.id)
                },
                onLayerUpdate: { layerId, newPosition in
                    viewModel.updateLayer(layerId, in: block.id) { layer in
                        layer.position = newPosition
                    }
                }
            )

            // Layer controls with glass cards
            if let layers = block.textLayers, !layers.isEmpty {
                layerControlsView(layers: layers, blockId: block.id)
            }

            // Add layer button
            Button(action: {
                viewModel.addTextLayer(to: block.id)
            }) {
                HStack {
                    Image(systemName: "text.badge.plus")
                    Text("Add Text Layer")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private func layerControlsView(layers: [TextLayer], blockId: UUID) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text("Layers")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text("\(layers.count)/10")
                    .font(.caption2)
                    .foregroundColor(.tertiary)
            }

            ForEach(layers) { layer in
                HStack(spacing: 12) {
                    // Visibility toggle
                    Button(action: {
                        viewModel.toggleLayerVisibility(layer.id, in: blockId)
                    }) {
                        Image(systemName: layer.visible ? "eye.fill" : "eye.slash.fill")
                            .foregroundColor(layer.visible ? .blue : .secondary)
                            .frame(width: 24)
                    }

                    // Layer preview
                    VStack(alignment: .leading, spacing: 2) {
                        Text(layer.text.isEmpty ? "Empty" : layer.text)
                            .font(.subheadline)
                            .lineLimit(1)

                        HStack(spacing: 4) {
                            if let animation = layer.animation {
                                Image(systemName: "sparkles")
                                    .font(.caption2)
                                Text(animation.preset.displayName)
                                    .font(.caption2)
                            }

                            if layer.path != nil {
                                Image(systemName: "point.topleft.down.to.point.bottomright.curvepath")
                                    .font(.caption2)
                                Text("Path")
                                    .font(.caption2)
                            }
                        }
                        .foregroundColor(.secondary)
                    }

                    Spacer()

                    // Path button (for motion path animations)
                    if layer.animation?.preset == .motionPath || layer.animation?.preset == .curvePath {
                        Button(action: {
                            editingLayer = layer
                            viewModel.selectLayer(layer.id, in: blockId)
                            showPathDrawing = true
                        }) {
                            Image(systemName: "scribble")
                                .foregroundStyle(.purple.gradient)
                                .font(.title3)
                        }
                    }

                    // Edit button
                    Button(action: {
                        editingLayer = layer
                        viewModel.selectLayer(layer.id, in: blockId)
                        showTextEditor = true
                    }) {
                        Image(systemName: "pencil.circle.fill")
                            .foregroundStyle(.blue.gradient)
                            .font(.title3)
                    }

                    // Delete button
                    Button(action: {
                        viewModel.deleteLayer(layer.id, from: blockId)
                    }) {
                        Image(systemName: "trash.circle.fill")
                            .foregroundColor(.red)
                            .font(.title3)
                    }
                }
                .padding(12)
                .background(
                    viewModel.selectedLayerId == layer.id ?
                        AnyView(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(.blue.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(.blue, lineWidth: 2)
                                )
                        ) :
                        AnyView(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(.ultraThinMaterial)
                        )
                )
            }
        }
    }

    private var editorToolbar: some View {
        HStack(spacing: 20) {
            // Play/Pause button
            Button(action: {
                viewModel.togglePlayback()
            }) {
                VStack(spacing: 4) {
                    Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.blue.gradient)
                    Text(viewModel.isPlaying ? "Pause" : "Play")
                        .font(.caption2)
                }
            }

            Spacer()

            // Add media button
            Button(action: {
                showMediaTypePicker = true
            }) {
                VStack(spacing: 4) {
                    Image(systemName: "photo.badge.plus")
                        .font(.title2)
                        .foregroundStyle(.purple.gradient)
                    Text("Media")
                        .font(.caption2)
                }
            }

            // Add text button
            Button(action: {
                if let blockId = viewModel.selectedBlockId ?? viewModel.blocks.first?.id {
                    viewModel.addTextLayer(to: blockId)
                }
            }) {
                VStack(spacing: 4) {
                    Image(systemName: "textformat")
                        .font(.title2)
                        .foregroundStyle(.green.gradient)
                    Text("Text")
                        .font(.caption2)
                }
            }
            .disabled(viewModel.blocks.isEmpty)

            // Lottie button
            Button(action: {
                showLottiePicker = true
            }) {
                VStack(spacing: 4) {
                    Image(systemName: "sparkles.tv")
                        .font(.title2)
                        .foregroundStyle(.orange.gradient)
                    Text("Lottie")
                        .font(.caption2)
                }
            }
            .disabled(viewModel.blocks.isEmpty)

            Spacer()

            // Help button
            Button(action: {
                showHelp = true
            }) {
                VStack(spacing: 4) {
                    Image(systemName: "info.circle")
                        .font(.title2)
                        .foregroundStyle(.secondary.opacity(0.7))
                    Text("Help")
                        .font(.caption2)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    // MARK: - Sheet Views

    private var mediaTypePickerView: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Add Media")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top, 20)

                Text("Loxation will handle media selection. This is a placeholder for the integration point.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                // Placeholder buttons
                VStack(spacing: 12) {
                    Button(action: {
                        // Placeholder: Loxation provides PHMediaPicker
                        // For now, create demo block
                        viewModel.addImageBlock(url: "https://picsum.photos/400/711", mediaId: "demo")
                        showMediaTypePicker = false
                    }) {
                        Label("Photo Library", systemImage: "photo.on.rectangle")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(12)
                    }

                    Button(action: {
                        // Placeholder: Loxation provides camera
                        viewModel.addVideoBlock(url: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4", mediaId: "demo")
                        showMediaTypePicker = false
                    }) {
                        Label("Camera", systemImage: "camera")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(12)
                    }
                }
                .padding()

                Spacer()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showMediaTypePicker = false
                    }
                }
            }
        }
    }

    private var helpView: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    helpSection(
                        icon: "hand.draw",
                        title: "Gestures",
                        tips: [
                            "Drag text layers to reposition",
                            "Pinch to scale text size",
                            "Rotate with two fingers",
                            "Tap to select a layer"
                        ]
                    )

                    helpSection(
                        icon: "sparkles",
                        title: "Animations",
                        tips: [
                            "Choose from 15+ presets",
                            "Adjust timing and delay",
                            "Loop animations continuously",
                            "Draw custom motion paths"
                        ]
                    )

                    helpSection(
                        icon: "paintbrush",
                        title: "Styling",
                        tips: [
                            "Select fonts and colors",
                            "Add shadows and outlines",
                            "Bold, italic, underline",
                            "Align text left/center/right"
                        ]
                    )

                    helpSection(
                        icon: "video",
                        title: "Video Support",
                        tips: [
                            "Add text to video backgrounds",
                            "Sync animations with playback",
                            "Muted during editing",
                            "Full playback on export"
                        ]
                    )
                }
                .padding()
            }
            .navigationTitle("Help")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        showHelp = false
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func helpSection(icon: String, title: String, tips: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(.blue.gradient)
                    .frame(width: 40)

                Text(title)
                    .font(.headline)
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(tips, id: \.self) { tip in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text(tip)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.leading, 52)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }

    // MARK: - Actions

    private func setupInitialMedia() {
        guard let media = initialMedia else { return }

        // Create block from initial media
        switch media {
        case .image:
            // Loxation will provide UIImage → we need to get URL after upload
            // For now, placeholder URL
            viewModel.addImageBlock(url: "placeholder", mediaId: "temp")
        case .video(let url):
            viewModel.addVideoBlock(url: url.absoluteString, mediaId: "temp")
        }
    }

    private func handleExport() {
        guard viewModel.validate() else {
            return
        }

        let content = viewModel.richContent
        onComplete(content)
    }
}

#endif
