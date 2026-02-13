//
// AnimatedPostEditorView.swift
// RichmediaEditor
//
// Main public API - Animated post editor container
//

import SwiftUI

#if canImport(UIKit)

public struct AnimatedPostEditorView: View {
    // MARK: - Properties

    let initialMedia: MediaInput?
    let onComplete: (RichPostContent) -> Void
    let onCancel: () -> Void

    @StateObject private var viewModel = AnimatedPostEditorViewModel()
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
        NavigationStack {
            VStack(spacing: 0) {
                if viewModel.blocks.isEmpty {
                    emptyStateView
                } else {
                    editorContentView
                }
            }
            .navigationTitle("Animated Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button("Export") {
                        handleExport()
                    }
                    .disabled(!viewModel.validate())
                }
            }
        }
        .onAppear {
            setupInitialMedia()
        }
    }

    // MARK: - Views

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("Create an Animated Post")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Add photos or videos with animated text overlays")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            VStack(spacing: 12) {
                Button(action: {
                    // TODO: Show media picker
                }) {
                    Label("Add Photo or Video", systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var editorContentView: some View {
        VStack(spacing: 0) {
            // Main canvas area
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(viewModel.blocks) { block in
                        blockPreviewCard(block)
                    }
                }
                .padding()
            }

            Divider()

            // Bottom toolbar
            editorToolbar
        }
    }

    private func blockPreviewCard(_ block: RichPostBlock) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Media preview
            ZStack {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .aspectRatio(9/16, contentMode: .fit)

                if let url = block.url {
                    Text(url)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding()
                }

                // Layer count badge
                if let layerCount = block.textLayers?.count, layerCount > 0 {
                    VStack {
                        HStack {
                            Spacer()
                            Text("\(layerCount) layer\(layerCount == 1 ? "" : "s")")
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.ultraThinMaterial)
                                .cornerRadius(8)
                                .padding(8)
                        }
                        Spacer()
                    }
                }
            }
            .cornerRadius(12)

            // Add layer button
            Button(action: {
                viewModel.addTextLayer(to: block.id)
            }) {
                Label("Add Text Layer", systemImage: "text.badge.plus")
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
    }

    private var editorToolbar: some View {
        HStack(spacing: 20) {
            Button(action: {
                viewModel.togglePlayback()
            }) {
                Label(viewModel.isPlaying ? "Pause" : "Play", systemImage: viewModel.isPlaying ? "pause.fill" : "play.fill")
            }

            Spacer()

            Button(action: {
                // TODO: Show media picker
            }) {
                Label("Media", systemImage: "photo")
            }

            Button(action: {
                if let blockId = viewModel.selectedBlockId {
                    viewModel.addTextLayer(to: blockId)
                }
            }) {
                Label("Text", systemImage: "textformat")
            }
            .disabled(viewModel.selectedBlockId == nil)
        }
        .padding()
        .background(Color(.systemGray6))
    }

    // MARK: - Actions

    private func setupInitialMedia() {
        guard let media = initialMedia else { return }

        // TODO: Handle initial media input
        // For now, this is a placeholder
        switch media {
        case .image:
            // Would add image block
            break
        case .video:
            // Would add video block
            break
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
