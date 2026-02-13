//
// AnimatedPostEditorView.swift
// RichmediaEditor
//
// Main public API - Animated post editor with modern glass UI
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
    @State private var showAnimationPicker = false
    @State private var editingLayer: TextLayer?
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
                // TODO: Show media picker
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
            Text("Layers")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

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

                        if let animation = layer.animation {
                            Text(animation.preset.displayName)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

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
                // TODO: Show media picker
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

            Spacer()

            // Info button
            Button(action: {
                // TODO: Show help/tips
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

    // MARK: - Actions

    private func setupInitialMedia() {
        guard let media = initialMedia else { return }

        // TODO: Handle initial media input
        // For now, create a placeholder block
        switch media {
        case .image:
            viewModel.addImageBlock(url: "placeholder", mediaId: "temp")
        case .video:
            viewModel.addVideoBlock(url: "placeholder", mediaId: "temp")
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
