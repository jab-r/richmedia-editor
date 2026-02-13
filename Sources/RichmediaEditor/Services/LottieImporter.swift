//
// LottieImporter.swift
// RichmediaEditor
//
// Import and parse Lottie JSON files from After Effects
//

import Foundation
import Lottie

#if canImport(UIKit)

/// Service for importing Lottie animations from JSON files
public enum LottieImporter {

    /// Import Lottie animation from JSON data
    public static func importAnimation(from data: Data, name: String) -> LottieAnimation? {
        guard let jsonString = String(data: data, encoding: .utf8) else {
            return nil
        }

        // Parse Lottie JSON to extract metadata
        guard let metadata = extractMetadata(from: data) else {
            return nil
        }

        return LottieAnimation(
            jsonData: jsonString,
            name: name,
            duration: metadata.duration,
            frameRate: metadata.frameRate,
            loops: metadata.loops
        )
    }

    /// Import Lottie animation from file URL
    public static func importAnimation(from url: URL) -> LottieAnimation? {
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }

        let name = url.deletingPathExtension().lastPathComponent
        return importAnimation(from: data, name: name)
    }

    /// Validate Lottie JSON format
    public static func validateLottieJSON(_ data: Data) -> Bool {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return false
        }

        // Basic Lottie format validation
        return json["v"] != nil && // Version
               json["fr"] != nil && // Frame rate
               json["ip"] != nil && // In point
               json["op"] != nil && // Out point
               json["layers"] != nil // Layers
    }

    /// Extract metadata from Lottie JSON
    private static func extractMetadata(from data: Data) -> (duration: TimeInterval, frameRate: Double, loops: Bool)? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        // Extract frame rate
        let frameRate = json["fr"] as? Double ?? 60.0

        // Extract in/out points
        let inPoint = json["ip"] as? Double ?? 0
        let outPoint = json["op"] as? Double ?? 0

        // Calculate duration in seconds
        let frameCount = outPoint - inPoint
        let duration = frameCount / frameRate

        // Check for loop marker (Lottie convention)
        let loops = json["loop"] as? Bool ?? false

        return (duration: duration, frameRate: frameRate, loops: loops)
    }

    /// Create LottieAnimationView from LottieAnimation model
    public static func createAnimationView(from animation: LottieAnimation) -> LottieAnimationView? {
        let animationView = LottieAnimationView()
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = animation.loops ? .loop : .playOnce

        // Load animation from JSON data
        if let data = animation.jsonData.data(using: .utf8),
           let lottieAnimation = try? JSONDecoder().decode(Lottie.LottieAnimation.self, from: data) {
            animationView.animation = lottieAnimation
        }

        return animationView
    }
}

// Prevent naming conflict with our model
typealias LottieAnimationFile = Lottie.LottieAnimation

extension Lottie.LottieAnimation {
    static func from(data: Data) throws -> Lottie.LottieAnimation {
        return try JSONDecoder().decode(Lottie.LottieAnimation.self, from: data)
    }
}

#endif
