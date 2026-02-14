//
// AnimatedPostEditorView.swift
// RichmediaEditor
//
// Main public API - Complete animated post editor with glass UI
//

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

#if canImport(UIKit)

public struct AnimatedPostEditorView: View {
    // MARK: - Properties

    let initialMedia: MediaInput?
    let onComplete: (RichPostContent, [UUID: UIImage]) -> Void
    let onCancel: () -> Void

    @StateObject private var viewModel = AnimatedPostEditorViewModel()
    @State private var showTextEditor = false
    @State private var showPathDrawing = false
    @State private var showAnimationPicker = false
    @State private var editingLayer: TextLayer?
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var mediaPickerTarget: UUID?
    @State private var showHelp = false
    @State private var showLottiePicker = false
    @State private var isGalleryMode = false
    @Environment(\.dismiss) private var dismiss

    // MARK: - Initialization

    public init(
        initialMedia: MediaInput? = nil,
        onComplete: @escaping (RichPostContent, [UUID: UIImage]) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.initialMedia = initialMedia
        self.onComplete = onComplete
        self.onCancel = onCancel
    }

    // MARK: - Body

    public var body: some View {
        NavigationStack {
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
                        Text("Done")
                    }
                    .foregroundStyle(viewModel.validate() ? .blue : .secondary)
                }
                .disabled(!viewModel.validate())
            }

            // Keyboard toolbar for inline text editing
            ToolbarItemGroup(placement: .keyboard) {
                keyboardStyleToolbar
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
                            if layer.animation == nil {
                                layer.animation = TextAnimation(preset: .motionPath, duration: 2.0)
                            }
                        }
                    }
                )
            }
        }
        .sheet(isPresented: $showAnimationPicker) {
            if let layer = editingLayer,
               let blockId = viewModel.selectedBlockId {
                AnimationPresetPicker(
                    selectedPreset: Binding(
                        get: { layer.animation?.preset },
                        set: { _ in }
                    ),
                    onSelect: { preset in
                        viewModel.updateLayer(layer.id, in: blockId) { layer in
                            if let existing = layer.animation {
                                layer.animation = TextAnimation(
                                    preset: preset,
                                    delay: existing.delay,
                                    duration: existing.duration,
                                    loop: existing.loop,
                                    loopDelay: existing.loopDelay
                                )
                            } else {
                                layer.animation = TextAnimation(preset: preset)
                            }
                        }
                    }
                )
            }
        }
        .onChange(of: selectedPhotoItems) { items in
            handlePickedMedia(items)
        }
        .onChange(of: viewModel.isPlaying) { playing in
            if playing {
                viewModel.editingLayerId = nil
                viewModel.selectedLayerId = nil
            }
        }
        .sheet(isPresented: $showHelp) {
            helpView
        }
        .sheet(isPresented: $showLottiePicker) {
            LottiePickerView { lottieAnimation in
                if let blockId = viewModel.selectedBlockId ?? viewModel.blocks.first?.id {
                    viewModel.setLottieOverlay(lottieAnimation, for: blockId)
                }
            }
        }
        .onAppear {
            setupInitialMedia()
        }
        } // NavigationStack
    }

    // MARK: - Views

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 120, height: 120)

                Image(systemName: "photo.badge.plus")
                    .font(.system(size: 50))
                    .foregroundStyle(.blue.gradient)
            }

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

            PhotosPicker(
                selection: pickerSelection(for: nil),
                maxSelectionCount: 10,
                matching: .any(of: [.images, .videos])
            ) {
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
            // Gallery mode toggle (if 2+ blocks)
            if viewModel.blocks.count >= 2 {
                GalleryModeToggle(isGalleryMode: $isGalleryMode, blockCount: viewModel.blocks.count)
                    .padding(.top, 8)
            }

            // Main canvas area
            if isGalleryMode && viewModel.blocks.count >= 2 {
                galleryView
            } else {
                stackView
            }

            // Floating selected-layer toolbar
            if viewModel.selectedLayerId != nil && !viewModel.isPlaying {
                selectedLayerToolbar
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            Divider()

            // Bottom toolbar
            editorToolbar
                .background(.ultraThinMaterial)
        }
    }

    private var stackView: some View {
        ScrollView {
            VStack(spacing: 20) {
                ForEach(viewModel.blocks) { block in
                    canvasCard(for: block)
                }
            }
            .padding()
        }
    }

    private var galleryView: some View {
        GalleryCanvasView(
            blocks: viewModel.blocks,
            selectedBlockId: $viewModel.selectedBlockId,
            selectedLayerId: $viewModel.selectedLayerId,
            onLayerTap: { blockId, layerId in
                handleLayerTap(layerId: layerId, blockId: blockId)
            },
            onLayerUpdate: { blockId, layerId, position in
                viewModel.updateLayer(layerId, in: blockId) { layer in
                    layer.position = position
                }
            },
            isPlaying: viewModel.isPlaying,
            isEditing: !viewModel.isPlaying,
            isTextEditingLayerId: viewModel.editingLayerId,
            onTextChange: { layerId, newText in
                guard let blockId = viewModel.selectedBlockId else { return }
                viewModel.updateLayer(layerId, in: blockId) { layer in
                    layer.text = newText
                }
            },
            onBackgroundTap: {
                viewModel.deselectAll()
            },
            onMediaTransformUpdate: { blockId, transform in
                viewModel.updateMediaTransform(transform, for: blockId)
            },
            localImages: viewModel.localImages
        )
        .padding(.horizontal)
    }

    @ViewBuilder
    private func canvasCard(for block: RichPostBlock) -> some View {
        MediaCanvasView(
            block: block,
            selectedLayerId: $viewModel.selectedLayerId,
            onLayerTap: { layerId in
                handleLayerTap(layerId: layerId, blockId: block.id)
            },
            onLayerUpdate: { layerId, newPosition in
                viewModel.updateLayer(layerId, in: block.id) { layer in
                    layer.position = newPosition
                }
            },
            isPlaying: viewModel.isPlaying,
            isEditing: !viewModel.isPlaying,
            isTextEditingLayerId: viewModel.editingLayerId,
            onTextChange: { layerId, newText in
                viewModel.updateLayer(layerId, in: block.id) { layer in
                    layer.text = newText
                }
            },
            onBackgroundTap: {
                viewModel.deselectAll()
            },
            onMediaTransformUpdate: { transform in
                viewModel.updateMediaTransform(transform, for: block.id)
            },
            localImage: viewModel.localImages[block.id]
        )
        .overlay(alignment: .topTrailing) {
            PhotosPicker(
                selection: pickerSelection(for: block.id),
                matching: .any(of: [.images, .videos])
            ) {
                Image(systemName: "arrow.triangle.2.circlepath.camera")
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(6)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            .padding(8)
        }
    }

    // MARK: - Selected Layer Toolbar

    private var selectedLayerToolbar: some View {
        HStack(spacing: 20) {
            // Edit text (opens full editor sheet)
            Button(action: {
                guard let blockId = viewModel.selectedBlockId,
                      let layerId = viewModel.selectedLayerId else { return }
                if let block = viewModel.blocks.first(where: { $0.id == blockId }),
                   let layer = block.textLayers?.first(where: { $0.id == layerId }) {
                    editingLayer = layer
                    showTextEditor = true
                }
            }) {
                VStack(spacing: 2) {
                    Image(systemName: "pencil")
                        .font(.title3)
                    Text("Style")
                        .font(.caption2)
                }
                .foregroundStyle(.blue)
            }

            // Animate
            Button(action: {
                guard let blockId = viewModel.selectedBlockId,
                      let layerId = viewModel.selectedLayerId else { return }
                if let block = viewModel.blocks.first(where: { $0.id == blockId }),
                   let layer = block.textLayers?.first(where: { $0.id == layerId }) {
                    editingLayer = layer
                    showAnimationPicker = true
                }
            }) {
                VStack(spacing: 2) {
                    Image(systemName: "sparkles")
                        .font(.title3)
                    Text("Animate")
                        .font(.caption2)
                }
                .foregroundStyle(.purple)
            }

            // Path (only for path animations)
            if let layer = viewModel.selectedLayer,
               layer.animation?.preset == .motionPath || layer.animation?.preset == .curvePath {
                Button(action: {
                    guard let blockId = viewModel.selectedBlockId else { return }
                    editingLayer = layer
                    showPathDrawing = true
                }) {
                    VStack(spacing: 2) {
                        Image(systemName: "scribble")
                            .font(.title3)
                        Text("Path")
                            .font(.caption2)
                    }
                    .foregroundStyle(.orange)
                }
            }

            // Visibility toggle
            if let layer = viewModel.selectedLayer {
                Button(action: {
                    guard let blockId = viewModel.selectedBlockId,
                          let layerId = viewModel.selectedLayerId else { return }
                    viewModel.toggleLayerVisibility(layerId, in: blockId)
                }) {
                    VStack(spacing: 2) {
                        Image(systemName: layer.visible ? "eye.fill" : "eye.slash.fill")
                            .font(.title3)
                        Text(layer.visible ? "Visible" : "Hidden")
                            .font(.caption2)
                    }
                    .foregroundStyle(.secondary)
                }
            }

            // Delete
            Button(action: {
                guard let blockId = viewModel.selectedBlockId,
                      let layerId = viewModel.selectedLayerId else { return }
                viewModel.deleteLayer(layerId, from: blockId)
            }) {
                VStack(spacing: 2) {
                    Image(systemName: "trash")
                        .font(.title3)
                    Text("Delete")
                        .font(.caption2)
                }
                .foregroundStyle(.red)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .padding(.horizontal)
        .padding(.vertical, 4)
    }

    // MARK: - Keyboard Style Toolbar

    @ViewBuilder
    private var keyboardStyleToolbar: some View {
        if viewModel.editingLayerId != nil, let layer = viewModel.selectedLayer {
            HStack(spacing: 12) {
                // Font picker
                Menu {
                    ForEach(["System", "Georgia", "Helvetica", "Courier", "Times New Roman"], id: \.self) { font in
                        Button(font) {
                            updateSelectedLayerStyle { $0.font = font }
                        }
                    }
                } label: {
                    Image(systemName: "textformat")
                        .font(.body)
                }

                // Color picker
                ColorPicker("", selection: Binding(
                    get: { Color(hex: layer.style.color) },
                    set: { newColor in
                        updateSelectedLayerStyle { $0.color = newColor.toHex() ?? "#FFFFFF" }
                    }
                ))
                .labelsHidden()
                .frame(width: 28, height: 28)

                Divider().frame(height: 20)

                // Bold
                Button(action: {
                    updateSelectedLayerStyle { $0.bold.toggle() }
                }) {
                    Image(systemName: "bold")
                        .foregroundStyle(layer.style.bold ? .blue : .primary)
                }

                // Italic
                Button(action: {
                    updateSelectedLayerStyle { $0.italic.toggle() }
                }) {
                    Image(systemName: "italic")
                        .foregroundStyle(layer.style.italic ? .blue : .primary)
                }

                // Underline
                Button(action: {
                    updateSelectedLayerStyle { $0.underline.toggle() }
                }) {
                    Image(systemName: "underline")
                        .foregroundStyle(layer.style.underline ? .blue : .primary)
                }

                Divider().frame(height: 20)

                // Alignment
                Menu {
                    Button(action: { updateSelectedLayerStyle { $0.align = .left } }) {
                        Label("Left", systemImage: "text.alignleft")
                    }
                    Button(action: { updateSelectedLayerStyle { $0.align = .center } }) {
                        Label("Center", systemImage: "text.aligncenter")
                    }
                    Button(action: { updateSelectedLayerStyle { $0.align = .right } }) {
                        Label("Right", systemImage: "text.alignright")
                    }
                } label: {
                    Image(systemName: alignmentIconForStyle(layer.style))
                }

                Spacer()

                // Done
                Button("Done") {
                    viewModel.editingLayerId = nil
                }
                .fontWeight(.semibold)
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
            PhotosPicker(
                selection: pickerSelection(for: nil),
                maxSelectionCount: 10,
                matching: .any(of: [.images, .videos])
            ) {
                VStack(spacing: 4) {
                    Image(systemName: "photo.badge.plus")
                        .font(.title2)
                        .foregroundStyle(.blue.gradient)
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

    // MARK: - Tap Handling

    private func handleLayerTap(layerId: UUID, blockId: UUID) {
        if viewModel.selectedLayerId == layerId {
            // Already selected — enter inline text editing
            viewModel.editingLayerId = layerId
        } else {
            // Select the layer
            viewModel.editingLayerId = nil
            viewModel.selectLayer(layerId, in: blockId)
        }
    }

    // MARK: - Style Helpers

    private func updateSelectedLayerStyle(_ updater: (inout TextLayerStyle) -> Void) {
        guard let blockId = viewModel.selectedBlockId,
              let layerId = viewModel.selectedLayerId else { return }
        viewModel.updateLayer(layerId, in: blockId) { layer in
            updater(&layer.style)
        }
    }

    private func alignmentIconForStyle(_ style: TextLayerStyle) -> String {
        switch style.align {
        case .left: return "text.alignleft"
        case .center: return "text.aligncenter"
        case .right: return "text.alignright"
        }
    }

    // MARK: - PhotosPicker Helpers

    private func pickerSelection(for target: UUID?) -> Binding<[PhotosPickerItem]> {
        Binding(
            get: { selectedPhotoItems },
            set: { items in
                mediaPickerTarget = target
                selectedPhotoItems = items
            }
        )
    }

    private func handlePickedMedia(_ items: [PhotosPickerItem]) {
        guard !items.isEmpty else { return }

        Task {
            if let target = mediaPickerTarget {
                if let item = items.first {
                    await loadMediaItem(item, replacingBlock: target)
                }
            } else {
                for item in items {
                    await loadMediaItem(item, replacingBlock: nil)
                }
            }

            selectedPhotoItems = []
            mediaPickerTarget = nil
        }
    }

    private func loadMediaItem(_ item: PhotosPickerItem, replacingBlock target: UUID?) async {
        if item.supportedContentTypes.contains(where: { $0.conforms(to: .movie) }),
           let movie = try? await item.loadTransferable(type: TransferableMovie.self) {
            if let target {
                viewModel.replaceBlockVideo(target, localURL: movie.url)
            } else {
                viewModel.addLocalVideoBlock(localURL: movie.url)
            }
        } else if let data = try? await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) {
            if let target {
                viewModel.replaceBlockImage(target, image: image)
            } else {
                viewModel.addLocalImageBlock(image: image)
            }
        }
    }

    // MARK: - Help View

    private var helpView: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    helpSection(
                        icon: "hand.draw",
                        title: "Gestures",
                        tips: [
                            "Tap text to select, tap again to edit inline",
                            "Drag text layers to reposition",
                            "Pinch to scale text size",
                            "Rotate with two fingers",
                            "Tap empty canvas to deselect"
                        ]
                    )

                    helpSection(
                        icon: "sparkles",
                        title: "Animations",
                        tips: [
                            "Select a layer, then tap Animate",
                            "Choose from 15+ presets",
                            "Tap Play to preview animations",
                            "Draw custom motion paths"
                        ]
                    )

                    helpSection(
                        icon: "paintbrush",
                        title: "Styling",
                        tips: [
                            "Quick style via keyboard toolbar",
                            "Full editor via Style button",
                            "Font, color, shadow, outline",
                            "Bold, italic, underline"
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
                        Text("\u{2022}")
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

        switch media {
        case .image(let uiImage, let url, let mediaId):
            if let uploadedUrl = url, let id = mediaId {
                viewModel.addImageBlock(url: uploadedUrl, mediaId: id)
            } else {
                viewModel.addLocalImageBlock(image: uiImage)
            }

        case .video(let videoUrl, let mediaId):
            if let id = mediaId {
                viewModel.addVideoBlock(url: videoUrl.absoluteString, mediaId: id)
            } else {
                viewModel.addLocalVideoBlock(localURL: videoUrl)
            }
        }
    }

    private func handleExport() {
        guard viewModel.validate() else {
            return
        }

        let content = viewModel.richContent
        onComplete(content, viewModel.localImages)
    }
}

// MARK: - Transferable Movie

private struct TransferableMovie: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { movie in
            SentTransferredFile(movie.url)
        } importing: { received in
            let ext = received.file.pathExtension.isEmpty ? "mov" : received.file.pathExtension
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("\(UUID().uuidString).\(ext)")
            try FileManager.default.copyItem(at: received.file, to: tempURL)
            return Self(url: tempURL)
        }
    }
}

#endif
