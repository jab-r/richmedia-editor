//
// AnimationPath.swift
// RichmediaEditor
//
// Path definitions for motion-based animations
//

import Foundation
import CoreGraphics

public struct AnimationPath: Codable, Equatable {
    public var type: PathType
    public var points: [CGPoint]
    public var curveType: CurveType

    public init(
        type: PathType,
        points: [CGPoint] = [],
        curveType: CurveType = .quadratic
    ) {
        self.type = type
        self.points = points
        self.curveType = curveType
    }
}

public enum PathType: String, Codable, Equatable {
    case linear      // Straight line movement
    case bezier      // Curved path movement
    case circular    // Text along circle
    case arc         // Text along arc
    case wave        // Text along wave
    case custom      // User-drawn path
}

public enum CurveType: String, Codable, Equatable {
    case quadratic   // 3 control points
    case cubic       // 4 control points
}
