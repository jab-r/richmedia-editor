//
// AnimatedPostEditorViewModel.swift
// RichmediaEditor
//
// State management for the animated post editor
//

import Foundation
import SwiftUI

@MainActor
public class AnimatedPostEditorViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published public var blocks: [RichPostBlock] = []
    @Published public var selectedBlockId: UUID?
    @Published public var selectedLayerId: UUID?
    @Published public var showingStyleEditor = false
    @Published public var showingAnimationPicker = false
    @Published public var isPlaying = false

    // MARK: - Local Media Storage

    /// Stores UIImages for blocks that haven't been uploaded yet
    /// Key: block.id, Value: UIImage
    @Published public var localImages: [UUID: UIImage] = [:]

    // MARK: - Computed Properties

    public var richContent: RichPostContent {
        RichPostContent(version: 1, blocks: blocks)
    }

    public var selectedBlock: RichPostBlock? {
        blocks.first(where: { $0.id == selectedBlockId })
    }

    public var selectedLayer: TextLayer? {
        guard let blockId = selectedBlockId,
              let block = blocks.first(where: { $0.id == blockId }),
              let layerId = selectedLayerId,
              let layer = block.textLayers?.first(where: { $0.id == layerId }) else {
            return nil
        }
        return layer
    }

    public var selectedBlockHasLayers: Bool {
        selectedBlock?.textLayers?.isEmpty == false
    }

    public var canAddLayer: Bool {
        // Limit to 10 layers per block
        guard let block = selectedBlock else { return false }
        return (block.textLayers?.count ?? 0) < 10
    }

    // MARK: - Initialization

    public init() {}

    // MARK: - Block Management

    /// Add image block with local UIImage (not yet uploaded)
    public func addLocalImageBlock(image: UIImage) {
        let newBlock = RichPostBlock(
            image: "local",  // Placeholder - will be replaced on upload
            url: nil,  // No URL until uploaded
            textLayers: []
        )
        blocks.append(newBlock)
        localImages[newBlock.id] = image
        selectedBlockId = newBlock.id
    }

    /// Add image block with uploaded URL (after upload)
    public func addImageBlock(url: String, mediaId: String) {
        let newBlock = RichPostBlock(
            image: mediaId,
            url: url,
            textLayers: []
        )
        blocks.append(newBlock)
        selectedBlockId = newBlock.id
    }

    /// Add video block with local URL (not yet uploaded)
    public func addLocalVideoBlock(localURL: URL) {
        let newBlock = RichPostBlock(
            video: "local",  // Placeholder - will be replaced on upload
            url: localURL.absoluteString,  // Local file URL
            textLayers: []
        )
        blocks.append(newBlock)
        selectedBlockId = newBlock.id
    }

    /// Add video block with uploaded URL (after upload)
    public func addVideoBlock(url: String, mediaId: String) {
        let newBlock = RichPostBlock(
            video: mediaId,
            url: url,
            textLayers: []
        )
        blocks.append(newBlock)
        selectedBlockId = newBlock.id
    }

    public func deleteBlock(_ id: UUID) {
        blocks.removeAll(where: { $0.id == id })
        if selectedBlockId == id {
            selectedBlockId = nil
            selectedLayerId = nil
        }
    }

    public func moveBlocks(from source: IndexSet, to destination: Int) {
        blocks.move(fromOffsets: source, toOffset: destination)
    }

    public func selectBlock(_ id: UUID) {
        selectedBlockId = id
        selectedLayerId = nil
    }

    // MARK: - Layer Management

    public func addTextLayer(to blockId: UUID? = nil) {
        let targetBlockId = blockId ?? selectedBlockId
        guard let blockIndex = blocks.firstIndex(where: { $0.id == targetBlockId }) else {
            return
        }

        let newLayer = TextLayer(
            text: "Text",
            position: LayerPosition(x: 0.5, y: 0.5),
            style: TextLayerStyle()
        )

        if blocks[blockIndex].textLayers == nil {
            blocks[blockIndex].textLayers = []
        }
        blocks[blockIndex].textLayers?.append(newLayer)

        selectedBlockId = targetBlockId
        selectedLayerId = newLayer.id
    }

    public func deleteLayer(_ layerId: UUID, from blockId: UUID) {
        guard let blockIndex = blocks.firstIndex(where: { $0.id == blockId }) else {
            return
        }

        blocks[blockIndex].textLayers?.removeAll(where: { $0.id == layerId })

        if selectedLayerId == layerId {
            selectedLayerId = nil
        }
    }

    public func updateLayer(_ layerId: UUID, in blockId: UUID, with updater: (inout TextLayer) -> Void) {
        guard let blockIndex = blocks.firstIndex(where: { $0.id == blockId }),
              var layers = blocks[blockIndex].textLayers,
              let layerIndex = layers.firstIndex(where: { $0.id == layerId }) else {
            return
        }

        updater(&layers[layerIndex])
        blocks[blockIndex].textLayers = layers
    }

    public func selectLayer(_ id: UUID?, in blockId: UUID?) {
        if let blockId = blockId {
            selectedBlockId = blockId
        }
        selectedLayerId = id
    }

    public func toggleLayerVisibility(_ layerId: UUID, in blockId: UUID) {
        updateLayer(layerId, in: blockId) { layer in
            layer.visible.toggle()
        }
    }

    // MARK: - Style Management

    public func updateLayerStyle(_ style: TextLayerStyle) {
        guard let blockId = selectedBlockId,
              let layerId = selectedLayerId else {
            return
        }

        updateLayer(layerId, in: blockId) { layer in
            layer.style = style
        }
    }

    public func updateLayerText(_ text: String) {
        guard let blockId = selectedBlockId,
              let layerId = selectedLayerId else {
            return
        }

        updateLayer(layerId, in: blockId) { layer in
            layer.text = text
        }
    }

    public func updateLayerPosition(_ position: LayerPosition) {
        guard let blockId = selectedBlockId,
              let layerId = selectedLayerId else {
            return
        }

        updateLayer(layerId, in: blockId) { layer in
            layer.position = position
        }
    }

    // MARK: - Animation Management

    public func updateLayerAnimation(_ animation: TextAnimation?) {
        guard let blockId = selectedBlockId,
              let layerId = selectedLayerId else {
            return
        }

        updateLayer(layerId, in: blockId) { layer in
            layer.animation = animation
        }
    }

    public func updateLayerPath(_ path: AnimationPath?) {
        guard let blockId = selectedBlockId,
              let layerId = selectedLayerId else {
            return
        }

        updateLayer(layerId, in: blockId) { layer in
            layer.path = path
        }
    }

    // MARK: - Lottie Management

    public func setLottieOverlay(_ lottie: LottieAnimation, for blockId: UUID? = nil) {
        let targetBlockId = blockId ?? selectedBlockId
        guard let blockIndex = blocks.firstIndex(where: { $0.id == targetBlockId }) else {
            return
        }
        blocks[blockIndex].lottieOverlay = lottie
    }

    // MARK: - Playback

    public func togglePlayback() {
        isPlaying.toggle()
    }

    // MARK: - Validation

    public func validate() -> Bool {
        // Must have at least one block
        guard !blocks.isEmpty else {
            return false
        }

        // Each block must have valid media reference
        for block in blocks {
            if block.url == nil {
                return false
            }
        }

        return true
    }
}
