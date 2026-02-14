//
// MediaTransform.swift
// RichmediaEditor
//
// Scale and offset for framing media within the canvas
//

import Foundation
import CoreGraphics

public struct MediaTransform: Codable, Equatable {
    /// Scale factor (1.0 = fit-to-frame, >1.0 = zoomed in)
    public var scale: CGFloat

    /// Horizontal offset as fraction of canvas width
    public var offsetX: CGFloat

    /// Vertical offset as fraction of canvas height
    public var offsetY: CGFloat

    public init(
        scale: CGFloat = 1.0,
        offsetX: CGFloat = 0,
        offsetY: CGFloat = 0
    ) {
        self.scale = scale
        self.offsetX = offsetX
        self.offsetY = offsetY
    }
}
