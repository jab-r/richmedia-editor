//
// LayerPosition.swift
// RichmediaEditor
//
// Position, rotation, and scale for a text layer
//

import Foundation
import CoreGraphics

public struct LayerPosition: Codable, Equatable {
    /// X position as percentage of canvas width (0.0 to 1.0)
    public var x: CGFloat

    /// Y position as percentage of canvas height (0.0 to 1.0)
    public var y: CGFloat

    /// Rotation in degrees
    public var rotation: CGFloat

    /// Scale factor (1.0 = original size)
    public var scale: CGFloat

    public init(
        x: CGFloat = 0.5,
        y: CGFloat = 0.5,
        rotation: CGFloat = 0,
        scale: CGFloat = 1.0
    ) {
        self.x = x
        self.y = y
        self.rotation = rotation
        self.scale = scale
    }
}
