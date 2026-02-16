//
// RichmediaEditorTests.swift
// RichmediaEditor
//
// Unit tests for richmedia editor models and services
//

import XCTest
@testable import RichmediaEditor

final class RichmediaEditorTests: XCTestCase {

    // MARK: - Model Tests

    func testTextLayerCreation() {
        let layer = TextLayer(
            text: "Hello World",
            position: LayerPosition(x: 0.5, y: 0.5),
            style: TextLayerStyle()
        )

        XCTAssertEqual(layer.text, "Hello World")
        XCTAssertEqual(layer.position.x, 0.5)
        XCTAssertEqual(layer.position.y, 0.5)
        XCTAssertTrue(layer.visible)
        XCTAssertEqual(layer.zIndex, 0)
    }

    func testAnimationPresetCategories() {
        // Original presets
        XCTAssertEqual(AnimationPreset.fadeIn.category, .entrance)
        XCTAssertEqual(AnimationPreset.fadeOut.category, .exit)
        XCTAssertEqual(AnimationPreset.pulse.category, .loop)
        XCTAssertEqual(AnimationPreset.motionPath.category, .path)

        // New entrance presets
        XCTAssertEqual(AnimationPreset.typewriter.category, .entrance)
        XCTAssertEqual(AnimationPreset.blurIn.category, .entrance)
        XCTAssertEqual(AnimationPreset.flipInX.category, .entrance)
        XCTAssertEqual(AnimationPreset.flipInY.category, .entrance)

        // New exit presets
        XCTAssertEqual(AnimationPreset.blurOut.category, .exit)
        XCTAssertEqual(AnimationPreset.shrinkOut.category, .exit)

        // New loop presets
        XCTAssertEqual(AnimationPreset.glow.category, .loop)
        XCTAssertEqual(AnimationPreset.shake.category, .loop)
        XCTAssertEqual(AnimationPreset.heartbeat.category, .loop)
        XCTAssertEqual(AnimationPreset.colorCycle.category, .loop)
        XCTAssertEqual(AnimationPreset.swing.category, .loop)
        XCTAssertEqual(AnimationPreset.flash.category, .loop)
    }

    func testAnimationPresetCount() {
        XCTAssertEqual(AnimationPreset.allCases.count, 29)
    }

    func testNewPresetDisplayNames() {
        XCTAssertEqual(AnimationPreset.typewriter.displayName, "Typewriter")
        XCTAssertEqual(AnimationPreset.blurIn.displayName, "Blur In")
        XCTAssertEqual(AnimationPreset.flipInX.displayName, "Flip In X")
        XCTAssertEqual(AnimationPreset.flipInY.displayName, "Flip In Y")
        XCTAssertEqual(AnimationPreset.blurOut.displayName, "Blur Out")
        XCTAssertEqual(AnimationPreset.shrinkOut.displayName, "Shrink Out")
        XCTAssertEqual(AnimationPreset.glow.displayName, "Glow")
        XCTAssertEqual(AnimationPreset.shake.displayName, "Shake")
        XCTAssertEqual(AnimationPreset.heartbeat.displayName, "Heartbeat")
        XCTAssertEqual(AnimationPreset.colorCycle.displayName, "Color Cycle")
        XCTAssertEqual(AnimationPreset.swing.displayName, "Swing")
        XCTAssertEqual(AnimationPreset.flash.displayName, "Flash")
    }

    func testNewPresetSerialization() {
        let newPresets: [AnimationPreset] = [
            .typewriter, .blurIn, .flipInX, .flipInY,
            .blurOut, .shrinkOut,
            .glow, .shake, .heartbeat, .colorCycle, .swing, .flash
        ]

        for preset in newPresets {
            let animation = TextAnimation(preset: preset, duration: 1.0)
            let encoder = JSONEncoder()
            let data = try! encoder.encode(animation)
            let decoded = try! JSONDecoder().decode(TextAnimation.self, from: data)
            XCTAssertEqual(decoded.preset, preset, "Round-trip failed for \(preset.rawValue)")
        }
    }

    func testRichPostContentSerialization() {
        let layer = TextLayer(
            text: "Test",
            position: LayerPosition(x: 0.5, y: 0.5),
            style: TextLayerStyle(
                font: "Helvetica",
                size: 32,
                color: "#FFFFFF"
            )
        )

        let block = RichPostBlock(
            image: "photo123",
            url: "https://example.com/photo.jpg",
            textLayers: [layer]
        )

        let content = RichPostContent(version: 1, blocks: [block])

        // Test JSON serialization
        let jsonString = content.toJSONString()
        XCTAssertNotNil(jsonString)

        // Test JSON deserialization
        let decoded = RichPostContent.fromJSONString(jsonString!)
        XCTAssertNotNil(decoded)
        XCTAssertEqual(decoded?.version, 1)
        XCTAssertEqual(decoded?.blocks.count, 1)
        XCTAssertEqual(decoded?.blocks.first?.textLayers?.count, 1)
        XCTAssertEqual(decoded?.blocks.first?.textLayers?.first?.text, "Test")
    }

    func testBlockTypeDetection() {
        let imageBlock = RichPostBlock(image: "photo123", url: "https://example.com/photo.jpg")
        XCTAssertEqual(imageBlock.blockType, .image)

        let videoBlock = RichPostBlock(video: "video456", url: "https://example.com/video.mp4")
        XCTAssertEqual(videoBlock.blockType, .video)

        let textBlock = RichPostBlock(textLayers: [])
        XCTAssertEqual(textBlock.blockType, .text)
    }

    // MARK: - ViewModel Tests

    @MainActor
    func testViewModelBlockManagement() {
        let viewModel = AnimatedPostEditorViewModel()

        // Initially empty
        XCTAssertTrue(viewModel.blocks.isEmpty)
        XCTAssertFalse(viewModel.validate())

        // Add image block
        viewModel.addImageBlock(url: "https://example.com/photo.jpg", mediaId: "photo123")
        XCTAssertEqual(viewModel.blocks.count, 1)
        XCTAssertTrue(viewModel.validate())
        XCTAssertNotNil(viewModel.selectedBlockId)

        // Add video block
        viewModel.addVideoBlock(url: "https://example.com/video.mp4", mediaId: "video456")
        XCTAssertEqual(viewModel.blocks.count, 2)
    }

    @MainActor
    func testViewModelLayerManagement() {
        let viewModel = AnimatedPostEditorViewModel()

        // Add block first
        viewModel.addImageBlock(url: "https://example.com/photo.jpg", mediaId: "photo123")
        let blockId = viewModel.selectedBlockId!

        // Add text layer
        viewModel.addTextLayer(to: blockId)
        XCTAssertEqual(viewModel.blocks.first?.textLayers?.count, 1)
        XCTAssertNotNil(viewModel.selectedLayerId)

        // Update layer text
        viewModel.updateLayerText("Updated Text")
        XCTAssertEqual(viewModel.selectedLayer?.text, "Updated Text")

        // Delete layer
        let layerId = viewModel.selectedLayerId!
        viewModel.deleteLayer(layerId, from: blockId)
        XCTAssertTrue(viewModel.blocks.first?.textLayers?.isEmpty ?? true)
    }

    @MainActor
    func testViewModelStyleManagement() {
        let viewModel = AnimatedPostEditorViewModel()

        // Setup
        viewModel.addImageBlock(url: "https://example.com/photo.jpg", mediaId: "photo123")
        viewModel.addTextLayer(to: viewModel.selectedBlockId!)

        // Update style
        var newStyle = TextLayerStyle()
        newStyle.bold = true
        newStyle.size = 48
        newStyle.color = "#FF6B35"

        viewModel.updateLayerStyle(newStyle)

        XCTAssertEqual(viewModel.selectedLayer?.style.bold, true)
        XCTAssertEqual(viewModel.selectedLayer?.style.size, 48)
        XCTAssertEqual(viewModel.selectedLayer?.style.color, "#FF6B35")
    }

    @MainActor
    func testViewModelAnimationManagement() {
        let viewModel = AnimatedPostEditorViewModel()

        // Setup
        viewModel.addImageBlock(url: "https://example.com/photo.jpg", mediaId: "photo123")
        viewModel.addTextLayer(to: viewModel.selectedBlockId!)

        // Add animation
        let animation = TextAnimation(
            preset: .fadeSlideUp,
            delay: 0.5,
            duration: 1.0,
            loop: false
        )

        viewModel.updateLayerAnimation(animation)

        XCTAssertNotNil(viewModel.selectedLayer?.animation)
        XCTAssertEqual(viewModel.selectedLayer?.animation?.preset, .fadeSlideUp)
        XCTAssertEqual(viewModel.selectedLayer?.animation?.delay, 0.5)
        XCTAssertEqual(viewModel.selectedLayer?.animation?.duration, 1.0)
    }
}
