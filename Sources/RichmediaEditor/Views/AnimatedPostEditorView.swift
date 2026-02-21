//
// AnimatedPostEditorView.swift
// RichmediaEditor
//
// Main public API - Complete animated post editor with glass UI
//

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import Combine
import CoreLocation
import ImageIO
import AVFoundation

#if canImport(UIKit)

public struct AnimatedPostEditorView: View {
    // MARK: - Properties

    let initialMediaItems: [MediaInput]
    let initialText: String?
    let existingContent: RichPostContent?
    let existingLocalImages: [UUID: UIImage]
    let onComplete: (RichPostContent, [UUID: UIImage], CLLocationCoordinate2D?) -> Void
    let onCancel: () -> Void

    @StateObject private var viewModel = AnimatedPostEditorViewModel()
    @State private var showTextEditor = false
    @State private var showPathDrawing = false
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var mediaPickerTarget: UUID?
    @State private var showHelp = false
    @State private var showLottiePicker = false
    @State private var showMusicPicker = false
    @StateObject private var audioPlayer = PreviewAudioPlayer()
    @State private var keyboardHeight: CGFloat = 0
    @State private var floatingText: String = ""
    @FocusState private var floatingFieldFocused: Bool
    @Environment(\.dismiss) private var dismiss

    // MARK: - Initialization

    /// Create editor with a single optional media item (backward-compatible)
    public init(
        initialMedia: MediaInput? = nil,
        onComplete: @escaping (RichPostContent, [UUID: UIImage], CLLocationCoordinate2D?) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.initialMediaItems = initialMedia.map { [$0] } ?? []
        self.initialText = nil
        self.existingContent = nil
        self.existingLocalImages = [:]
        self.onComplete = onComplete
        self.onCancel = onCancel
    }

    /// Create editor with multiple media items and optional initial text
    public init(
        media: [MediaInput],
        initialText: String? = nil,
        onComplete: @escaping (RichPostContent, [UUID: UIImage], CLLocationCoordinate2D?) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.initialMediaItems = media
        self.initialText = initialText
        self.existingContent = nil
        self.existingLocalImages = [:]
        self.onComplete = onComplete
        self.onCancel = onCancel
    }

    /// Create editor to re-edit existing content
    public init(
        content: RichPostContent,
        localImages: [UUID: UIImage] = [:],
        onComplete: @escaping (RichPostContent, [UUID: UIImage], CLLocationCoordinate2D?) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.initialMediaItems = []
        self.initialText = nil
        self.existingContent = content
        self.existingLocalImages = localImages
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

            // Floating text input above keyboard
            if viewModel.editingLayerId != nil {
                VStack {
                    Spacer()
                    floatingTextInput
                }
                .padding(.bottom, keyboardHeight)
            }
        }
        .ignoresSafeArea(.keyboard)
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
        }
        .sheet(isPresented: $showTextEditor) {
            if let blockId = viewModel.selectedBlockId,
               let layerId = viewModel.selectedLayerId,
               let blockIndex = viewModel.blocks.firstIndex(where: { $0.id == blockId }),
               let layerIndex = viewModel.blocks[blockIndex].textLayers?.firstIndex(where: { $0.id == layerId }) {
                let layer = viewModel.blocks[blockIndex].textLayers![layerIndex]
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
            if let blockId = viewModel.selectedBlockId,
               let layerId = viewModel.selectedLayerId,
               let block = viewModel.blocks.first(where: { $0.id == blockId }),
               let layer = block.textLayers?.first(where: { $0.id == layerId }) {
                PathDrawingView(
                    path: Binding(
                        get: { layer.path },
                        set: { _ in }
                    ),
                    onComplete: { path in
                        viewModel.updateLayer(layerId, in: blockId) { layer in
                            layer.path = path
                            if layer.animation == nil {
                                layer.animation = TextAnimation(preset: .motionPath, duration: 2.0)
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
                // Start music preview if a track is set
                if let track = viewModel.musicTrack {
                    audioPlayer.play(track)
                }
            } else {
                audioPlayer.pause()
            }
        }
        .onChange(of: viewModel.musicTrack) { track in
            // If track removed, stop audio
            if track == nil {
                audioPlayer.stop()
            }
        }
        .onDisappear {
            audioPlayer.stop()
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
        .sheet(isPresented: $showMusicPicker) {
            MusicSearchView(
                currentTrack: viewModel.musicTrack,
                onSelect: { track in
                    viewModel.setMusicTrack(track)
                }
            )
        }
        .onAppear {
            setupInitialContent()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
            if let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
               let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double {
                withAnimation(.easeOut(duration: duration)) {
                    keyboardHeight = frame.height
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { notification in
            let duration = (notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double) ?? 0.25
            withAnimation(.easeOut(duration: duration)) {
                keyboardHeight = 0
            }
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
            // Music indicator pill
            if let track = viewModel.musicTrack {
                musicIndicator(track: track)
            }

            // Main canvas area — always gallery mode
            galleryView

            Divider()

            // Bottom toolbar
            editorToolbar
                .background(.ultraThinMaterial)
        }
    }

    private func musicIndicator(track: MusicTrack) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "music.note")
                .font(.caption)
                .foregroundStyle(.pink.gradient)

            Text("\(track.trackName) — \(track.artistName)")
                .font(.caption2)
                .lineLimit(1)

            Spacer()

            Button(action: {
                viewModel.setMusicTrack(nil)
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .onTapGesture {
            showMusicPicker = true
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
                if viewModel.editingLayerId != nil {
                    finishEditing()
                } else {
                    viewModel.deselectAll()
                }
            },
            onMediaTransformUpdate: { blockId, transform in
                viewModel.updateMediaTransform(transform, for: blockId)
            },
            localImages: viewModel.localImages,
            onLayerDelete: { blockId, layerId in
                viewModel.deleteLayer(layerId, from: blockId)
            },
            onLayerLongPress: { blockId, layerId in
                handleLayerLongPress(layerId: layerId, blockId: blockId)
            }
        )
        .padding(.horizontal)
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
                    if let newLayerId = viewModel.selectedLayerId {
                        viewModel.editingLayerId = newLayerId
                        floatingText = "Text"
                        floatingFieldFocused = true
                    }
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

            // Music button
            Button(action: {
                showMusicPicker = true
            }) {
                VStack(spacing: 4) {
                    Image(systemName: viewModel.musicTrack != nil ? "music.note.list" : "music.note")
                        .font(.title2)
                        .foregroundStyle(.pink.gradient)
                    Text("Music")
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

    // MARK: - Floating Text Input

    private var floatingTextInput: some View {
        HStack(spacing: 12) {
            TextField("Enter text", text: $floatingText, axis: .vertical)
                .textFieldStyle(.plain)
                .focused($floatingFieldFocused)
                .onChange(of: floatingText) { newValue in
                    guard let blockId = viewModel.selectedBlockId,
                          let layerId = viewModel.editingLayerId else { return }
                    viewModel.updateLayer(layerId, in: blockId) { layer in
                        layer.text = newValue
                    }
                }

            Button("Done") {
                finishEditing()
            }
            .fontWeight(.semibold)
            .foregroundColor(.blue)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .padding(.horizontal, 8)
        .padding(.bottom, 4)
    }

    private func finishEditing() {
        floatingFieldFocused = false
        let trimmed = floatingText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty,
           let blockId = viewModel.selectedBlockId,
           let layerId = viewModel.editingLayerId {
            viewModel.deleteLayer(layerId, from: blockId)
        }
        viewModel.editingLayerId = nil
    }

    // MARK: - Tap / Long Press Handling

    private func handleLayerTap(layerId: UUID, blockId: UUID) {
        // Single tap — select and enter floating text editing
        viewModel.selectLayer(layerId, in: blockId)
        viewModel.editingLayerId = layerId

        // Initialize floating text from the layer's current text
        if let block = viewModel.blocks.first(where: { $0.id == blockId }),
           let layer = block.textLayers?.first(where: { $0.id == layerId }) {
            floatingText = layer.text
        }
        floatingFieldFocused = true
    }

    private func handleLayerLongPress(layerId: UUID, blockId: UUID) {
        // Long press — select the layer and open style/animate editor
        viewModel.editingLayerId = nil
        viewModel.selectLayer(layerId, in: blockId)
        showTextEditor = true
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
            // Extract GPS from video's QuickTime metadata if no location yet
            if viewModel.firstImageLocation == nil {
                viewModel.firstImageLocation = await Self.extractVideoGPSLocation(from: movie.url)
            }
            if let target {
                viewModel.replaceBlockVideo(target, localURL: movie.url)
            } else {
                viewModel.addLocalVideoBlock(localURL: movie.url)
            }
        } else if let data = try? await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) {
            // Extract EXIF GPS from first image for post location
            if viewModel.firstImageLocation == nil {
                viewModel.firstImageLocation = Self.extractGPSLocation(from: data)
            }
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
                            "Tap text to edit inline",
                            "Long press text for style & animation",
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
                            "Long press a layer to open style & animation",
                            "Choose from 15+ presets",
                            "Tap Play to preview animations",
                            "Draw custom motion paths"
                        ]
                    )

                    helpSection(
                        icon: "paintbrush",
                        title: "Styling",
                        tips: [
                            "Long press a layer to open style editor",
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

    private func setupInitialContent() {
        // Case 1: Re-edit existing content
        if let content = existingContent {
            viewModel.loadContent(content, localImages: existingLocalImages)
            return
        }

        // Case 2: Load media items
        for media in initialMediaItems {
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

        // Select the first block so the visible page matches selectedBlockId
        if !initialMediaItems.isEmpty, let firstBlock = viewModel.blocks.first {
            viewModel.selectedBlockId = firstBlock.id
        }

        // Case 3: Add initial text
        if let text = initialText, !text.isEmpty {
            if viewModel.blocks.isEmpty {
                // No media — create a blank block to hold the text
                let blankBlock = RichPostBlock(textLayers: [])
                viewModel.blocks.append(blankBlock)
                viewModel.selectedBlockId = blankBlock.id
            }
            if let firstBlockId = viewModel.blocks.first?.id {
                viewModel.addTextLayer(to: firstBlockId, text: text)
            }
        }
    }

    private func handleExport() {
        guard viewModel.validate() else {
            return
        }

        let content = viewModel.richContent
        onComplete(content, viewModel.localImages, viewModel.firstImageLocation)
    }

    // MARK: - EXIF GPS Extraction

    /// Extract GPS coordinates from raw image data using ImageIO.
    private static func extractGPSLocation(from imageData: Data) -> CLLocationCoordinate2D? {
        guard let source = CGImageSourceCreateWithData(imageData as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let gps = properties[kCGImagePropertyGPSDictionary] as? [CFString: Any] else {
            return nil
        }
        guard let latitude = gps[kCGImagePropertyGPSLatitude] as? Double,
              let latitudeRef = gps[kCGImagePropertyGPSLatitudeRef] as? String,
              let longitude = gps[kCGImagePropertyGPSLongitude] as? Double,
              let longitudeRef = gps[kCGImagePropertyGPSLongitudeRef] as? String else {
            return nil
        }
        let lat = latitudeRef == "S" ? -latitude : latitude
        let lon = longitudeRef == "W" ? -longitude : longitude
        guard (-90...90).contains(lat), (-180...180).contains(lon) else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    /// Extract GPS coordinates from video QuickTime metadata (ISO 6709 format).
    private static func extractVideoGPSLocation(from url: URL) async -> CLLocationCoordinate2D? {
        let asset = AVAsset(url: url)
        guard let item = try? await AVMetadataItem.metadataItems(
            from: asset.load(.metadata),
            filteredByIdentifier: .quickTimeMetadataLocationISO6709
        ).first,
        let str = try? await item.load(.stringValue) else {
            return nil
        }
        // ISO 6709 format: "+DD.DDDD-DDD.DDDD" or "+DD.DDDD+DDD.DDDD+AAA.AAA/"
        let pattern = "([+-][0-9.]+)([+-][0-9.]+)"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: str, range: NSRange(str.startIndex..., in: str)),
              let latRange = Range(match.range(at: 1), in: str),
              let lonRange = Range(match.range(at: 2), in: str),
              let lat = Double(str[latRange]),
              let lon = Double(str[lonRange]),
              (-90...90).contains(lat), (-180...180).contains(lon) else {
            return nil
        }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
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
