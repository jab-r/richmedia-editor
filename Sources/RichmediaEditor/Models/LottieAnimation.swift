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

// Lottie metadata fields are now stored directly in TextLayer and RichPostBlock models
