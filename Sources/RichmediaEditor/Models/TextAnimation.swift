//
// TextAnimation.swift
// RichmediaEditor
//
// Animation properties for text layers
//

import Foundation

public struct TextAnimation: Codable, Equatable {
    public var preset: AnimationPreset
    public var delay: TimeInterval
    public var duration: TimeInterval
    public var loop: Bool
    public var loopDelay: TimeInterval

    public init(
        preset: AnimationPreset,
        delay: TimeInterval = 0,
        duration: TimeInterval = 0.8,
        loop: Bool = false,
        loopDelay: TimeInterval = 0
    ) {
        self.preset = preset
        self.delay = delay
        self.duration = duration
        self.loop = loop
        self.loopDelay = loopDelay
    }
}

public enum AnimationPreset: String, Codable, Equatable, CaseIterable {
    // Entrance effects
    case fadeIn
    case fadeSlideUp
    case fadeSlideDown
    case fadeSlideLeft
    case fadeSlideRight
    case zoomIn
    case bounceIn
    case popIn

    // Exit effects
    case fadeOut
    case slideOutUp
    case slideOutDown
    case zoomOut

    // Looping effects
    case pulse
    case bounce
    case float
    case wiggle
    case rotate

    // Path-based (requires AnimationPath)
    case motionPath
    case curvePath

    /// Display name for UI
    public var displayName: String {
        switch self {
        case .fadeIn: return "Fade In"
        case .fadeSlideUp: return "Slide Up"
        case .fadeSlideDown: return "Slide Down"
        case .fadeSlideLeft: return "Slide Left"
        case .fadeSlideRight: return "Slide Right"
        case .zoomIn: return "Zoom In"
        case .bounceIn: return "Bounce In"
        case .popIn: return "Pop In"
        case .fadeOut: return "Fade Out"
        case .slideOutUp: return "Slide Out Up"
        case .slideOutDown: return "Slide Out Down"
        case .zoomOut: return "Zoom Out"
        case .pulse: return "Pulse"
        case .bounce: return "Bounce"
        case .float: return "Float"
        case .wiggle: return "Wiggle"
        case .rotate: return "Rotate"
        case .motionPath: return "Motion Path"
        case .curvePath: return "Curve Path"
        }
    }

    /// Category for grouping in UI
    public var category: AnimationCategory {
        switch self {
        case .fadeIn, .fadeSlideUp, .fadeSlideDown, .fadeSlideLeft, .fadeSlideRight, .zoomIn, .bounceIn, .popIn:
            return .entrance
        case .fadeOut, .slideOutUp, .slideOutDown, .zoomOut:
            return .exit
        case .pulse, .bounce, .float, .wiggle, .rotate:
            return .loop
        case .motionPath, .curvePath:
            return .path
        }
    }
}

public enum AnimationCategory: String, CaseIterable {
    case entrance = "Entrance"
    case exit = "Exit"
    case loop = "Loop"
    case path = "Path"
}
