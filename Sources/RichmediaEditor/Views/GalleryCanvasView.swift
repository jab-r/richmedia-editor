//
// GalleryCanvasView.swift
// RichmediaEditor
//
// TikTok-style photo gallery with horizontal swipe
//

import SwiftUI

#if canImport(UIKit)

/// TikTok-style swipeable photo gallery
struct GalleryCanvasView: View {
    let blocks: [RichPostBlock]
    @Binding var selectedBlockId: UUID?
    @Binding var selectedLayerId: UUID?
    let onLayerTap: (UUID, UUID) -> Void  // blockId, layerId
    let onLayerUpdate: (UUID, UUID, LayerPosition) -> Void  // blockId, layerId, position
    var isPlaying: Bool = false
    var isEditing: Bool = true
    var isTextEditingLayerId: UUID? = nil
    var onTextChange: ((UUID, String) -> Void)? = nil  // layerId, newText
    var onBackgroundTap: (() -> Void)? = nil
    var onMediaTransformUpdate: ((UUID, MediaTransform) -> Void)? = nil  // blockId, transform
    var localImages: [UUID: UIImage] = [:]
    var onLayerDelete: ((UUID, UUID) -> Void)? = nil  // blockId, layerId
    var onLayerLongPress: ((UUID, UUID) -> Void)? = nil  // blockId, layerId

    @State private var currentPage = 0

    var body: some View {
        VStack(spacing: 0) {
            // Gallery with horizontal swipe
            TabView(selection: $currentPage) {
                ForEach(Array(blocks.enumerated()), id: \.element.id) { index, block in
                    MediaCanvasView(
                        block: block,
                        selectedLayerId: $selectedLayerId,
                        onLayerTap: { layerId in
                            selectedBlockId = block.id
                            onLayerTap(block.id, layerId)
                        },
                        onLayerUpdate: { layerId, position in
                            onLayerUpdate(block.id, layerId, position)
                        },
                        isPlaying: isPlaying,
                        isEditing: isEditing,
                        isTextEditingLayerId: isTextEditingLayerId,
                        onTextChange: onTextChange,
                        onBackgroundTap: onBackgroundTap,
                        onMediaTransformUpdate: { transform in
                            onMediaTransformUpdate?(block.id, transform)
                        },
                        localImage: localImages[block.id],
                        onLayerDelete: { layerId in
                            onLayerDelete?(block.id, layerId)
                        },
                        onLayerLongPress: { layerId in
                            onLayerLongPress?(block.id, layerId)
                        }
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .onAppear {
                // Sync selected block with initial page
                if blocks.indices.contains(currentPage) {
                    selectedBlockId = blocks[currentPage].id
                }
            }
            .onChange(of: currentPage) { newPage in
                // Update selected block when page changes
                if blocks.indices.contains(newPage) {
                    selectedBlockId = blocks[newPage].id
                }
            }

            // Page indicator with photo counts
            pageIndicator
                .padding(.top, 8)
        }
    }

    private var pageIndicator: some View {
        HStack(spacing: 12) {
            // Previous button
            Button(action: {
                withAnimation {
                    if currentPage > 0 {
                        currentPage -= 1
                    }
                }
            }) {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.title3)
                    .foregroundColor(currentPage > 0 ? .blue : .secondary.opacity(0.3))
            }
            .disabled(currentPage == 0)

            // Page counter
            Text("\(currentPage + 1) / \(blocks.count)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial)
                .cornerRadius(12)

            // Next button
            Button(action: {
                withAnimation {
                    if currentPage < blocks.count - 1 {
                        currentPage += 1
                    }
                }
            }) {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.title3)
                    .foregroundColor(currentPage < blocks.count - 1 ? .blue : .secondary.opacity(0.3))
            }
            .disabled(currentPage == blocks.count - 1)
        }
    }
}

#endif
