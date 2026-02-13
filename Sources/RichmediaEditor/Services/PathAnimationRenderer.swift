//
// PathAnimationRenderer.swift
// RichmediaEditor
//
// CAKeyframeAnimation-based path animations (motion along curves)
//

import Foundation
import SwiftUI
import QuartzCore

#if canImport(UIKit)
import UIKit

/// Renders path-based animations using CAKeyframeAnimation
public enum PathAnimationRenderer {

    /// Apply path-based animation to a UIView (for integration with UIViewRepresentable)
    public static func animateAlongPath(
        view: UIView,
        path: AnimationPath,
        duration: TimeInterval,
        delay: TimeInterval = 0
    ) {
        let bezierPath = createBezierPath(from: path, in: view.bounds)

        let animation = CAKeyframeAnimation(keyPath: "position")
        animation.path = bezierPath.cgPath
        animation.duration = duration
        animation.beginTime = CACurrentMediaTime() + delay
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false

        // Optional: Rotate view along path tangent
        animation.rotationMode = .rotateAuto

        view.layer.add(animation, forKey: "pathAnimation")
    }

    /// Create UIBezierPath from AnimationPath definition
    private static func createBezierPath(from path: AnimationPath, in bounds: CGRect) -> UIBezierPath {
        let bezierPath = UIBezierPath()

        guard !path.points.isEmpty else {
            return bezierPath
        }

        // Convert normalized points (0-1) to absolute coordinates
        let absolutePoints = path.points.map { point in
            CGPoint(
                x: point.x * bounds.width,
                y: point.y * bounds.height
            )
        }

        bezierPath.move(to: absolutePoints[0])

        switch path.type {
        case .linear:
            // Straight lines between points
            for point in absolutePoints.dropFirst() {
                bezierPath.addLine(to: point)
            }

        case .bezier:
            // Smooth bezier curve
            if absolutePoints.count == 3 && path.curveType == .quadratic {
                // Quadratic curve (3 points)
                bezierPath.addQuadCurve(
                    to: absolutePoints[2],
                    controlPoint: absolutePoints[1]
                )
            } else if absolutePoints.count == 4 && path.curveType == .cubic {
                // Cubic curve (4 points)
                bezierPath.addCurve(
                    to: absolutePoints[3],
                    controlPoint1: absolutePoints[1],
                    controlPoint2: absolutePoints[2]
                )
            } else {
                // Multiple points: create smooth curve using Catmull-Rom spline
                createSmoothCurve(bezierPath: bezierPath, through: absolutePoints)
            }

        case .circular:
            // Circle path
            let center = CGPoint(x: bounds.midX, y: bounds.midY)
            let radius = min(bounds.width, bounds.height) / 2 * 0.8
            bezierPath.addArc(
                withCenter: center,
                radius: radius,
                startAngle: 0,
                endAngle: 2 * .pi,
                clockwise: true
            )

        case .arc:
            // Arc path (quarter circle)
            let center = CGPoint(x: bounds.midX, y: bounds.midY)
            let radius = min(bounds.width, bounds.height) / 2 * 0.8
            bezierPath.addArc(
                withCenter: center,
                radius: radius,
                startAngle: 0,
                endAngle: .pi / 2,
                clockwise: true
            )

        case .wave:
            // Sine wave
            let steps = 50
            for i in 1...steps {
                let t = CGFloat(i) / CGFloat(steps)
                let x = t * bounds.width
                let y = bounds.midY + sin(t * 4 * .pi) * bounds.height * 0.2
                bezierPath.addLine(to: CGPoint(x: x, y: y))
            }

        case .custom:
            // Custom path from drawn points
            createSmoothCurve(bezierPath: bezierPath, through: absolutePoints)
        }

        return bezierPath
    }

    /// Create smooth curve through multiple points using Catmull-Rom spline
    private static func createSmoothCurve(bezierPath: UIBezierPath, through points: [CGPoint]) {
        guard points.count > 2 else {
            // Fall back to lines
            for point in points.dropFirst() {
                bezierPath.addLine(to: point)
            }
            return
        }

        // Catmull-Rom spline interpolation
        let tension: CGFloat = 0.5  // Controls curve tightness (0 = sharp, 1 = smooth)

        for i in 0..<(points.count - 1) {
            let p0 = i > 0 ? points[i - 1] : points[i]
            let p1 = points[i]
            let p2 = points[i + 1]
            let p3 = i + 2 < points.count ? points[i + 2] : p2

            // Calculate control points
            let cp1 = CGPoint(
                x: p1.x + (p2.x - p0.x) / 6 * tension,
                y: p1.y + (p2.y - p0.y) / 6 * tension
            )
            let cp2 = CGPoint(
                x: p2.x - (p3.x - p1.x) / 6 * tension,
                y: p2.y - (p3.y - p1.y) / 6 * tension
            )

            bezierPath.addCurve(to: p2, controlPoint1: cp1, controlPoint2: cp2)
        }
    }
}

/// SwiftUI wrapper for path animations (converts SwiftUI View to UIView for CALayer access)
struct PathAnimatedView<Content: View>: UIViewRepresentable {
    let content: Content
    let path: AnimationPath
    let duration: TimeInterval
    let delay: TimeInterval

    func makeUIView(context: Context) -> UIView {
        let hostingController = UIHostingController(rootView: content)
        hostingController.view.backgroundColor = .clear
        return hostingController.view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // Apply animation when view updates
        PathAnimationRenderer.animateAlongPath(
            view: uiView,
            path: path,
            duration: duration,
            delay: delay
        )
    }
}

#endif
