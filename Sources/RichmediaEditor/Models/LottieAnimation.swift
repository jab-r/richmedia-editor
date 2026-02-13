//
// LottieAnimation.swift
// RichmediaEditor
//
// Lottie animation integration for professional-grade animations
//

import Foundation

/// Wrapper for imported Lottie animation data
public struct LottieAnimation: Codable, Equatable {
    /// Lottie JSON data (full animation definition)
    public let jsonData: String

    /// Animation name/identifier
    public let name: String

    /// Duration in seconds (extracted from Lottie metadata)
    public let duration: TimeInterval

    /// Frame rate (fps)
    public let frameRate: Double

    /// Whether animation loops
    public let loops: Bool

    public init(
        jsonData: String,
        name: String,
        duration: TimeInterval,
        frameRate: Double = 60,
        loops: Bool = false
    ) {
        self.jsonData = jsonData
        self.name = name
        self.duration = duration
        self.frameRate = frameRate
        self.loops = loops
    }
}

/// Extended TextLayer to support Lottie animations
extension TextLayer {
    /// Lottie animation data (alternative to preset animations)
    public var lottieAnimation: LottieAnimation? {
        get {
            // TODO: Store in custom metadata field
            return nil
        }
        set {
            // TODO: Store in custom metadata field
        }
    }
}

/// Extended RichPostBlock to support full-canvas Lottie overlays
extension RichPostBlock {
    /// Lottie overlay animation (plays on top of media)
    public var lottieOverlay: LottieAnimation? {
        get {
            // TODO: Store in custom metadata field
            return nil
        }
        set {
            // TODO: Store in custom metadata field
        }
    }
}
