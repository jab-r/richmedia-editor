//
// PathDrawingView.swift
// RichmediaEditor
//
// Interactive path drawing for motion-based animations
//

import SwiftUI

#if canImport(UIKit)

struct PathDrawingView: View {
    @Binding var path: AnimationPath?
    let onComplete: (AnimationPath) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var drawnPoints: [CGPoint] = []
    @State private var showPreview = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Drawing canvas
                Canvas { context, size in
                    if !drawnPoints.isEmpty {
                        var path = Path()
                        path.move(to: drawnPoints[0])

                        if drawnPoints.count > 2 {
                            // Draw smooth bezier curve through points
                            for i in 1..<drawnPoints.count {
                                path.addLine(to: drawnPoints[i])
                            }
                        }

                        context.stroke(
                            path,
                            with: .color(.blue),
                            lineWidth: 3
                        )

                        // Draw control points
                        for point in drawnPoints {
                            context.fill(
                                Path(ellipseIn: CGRect(x: point.x - 5, y: point.y - 5, width: 10, height: 10)),
                                with: .color(.blue)
                            )
                        }
                    }
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            drawnPoints.append(value.location)
                        }
                        .onEnded { _ in
                            // Simplify points (keep every 5th point for smoother curve)
                            if drawnPoints.count > 10 {
                                drawnPoints = stride(from: 0, to: drawnPoints.count, by: 5).map { drawnPoints[$0] }
                            }
                        }
                )

                // Instructions overlay
                if drawnPoints.isEmpty {
                    VStack {
                        Spacer()
                        instructionsView
                        Spacer()
                    }
                }
            }
            .background(Color(.systemGray6))
            .navigationTitle("Draw Path")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        savePath()
                    }
                    .disabled(drawnPoints.count < 3)
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    Button {
                        drawnPoints.removeAll()
                    } label: {
                        Label("Clear", systemImage: "trash")
                    }
                    .disabled(drawnPoints.isEmpty)

                    Spacer()

                    Button {
                        loadPresetPath(.circular)
                    } label: {
                        Label("Circle", systemImage: "circle")
                    }

                    Button {
                        loadPresetPath(.wave)
                    } label: {
                        Label("Wave", systemImage: "waveform")
                    }

                    Button {
                        loadPresetPath(.arc)
                    } label: {
                        Label("Arc", systemImage: "arrow.turn.up.right")
                    }
                }
            }
        }
    }

    private var instructionsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "hand.draw")
                .font(.system(size: 60))
                .foregroundStyle(.blue.gradient)

            Text("Draw a Path")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Drag your finger to draw the path your text will follow")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Text("Or choose a preset below")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .padding(40)
    }

    private func savePath() {
        guard drawnPoints.count >= 3 else { return }

        // Normalize points to 0-1 range
        let minX = drawnPoints.map { $0.x }.min() ?? 0
        let maxX = drawnPoints.map { $0.x }.max() ?? 1
        let minY = drawnPoints.map { $0.y }.min() ?? 0
        let maxY = drawnPoints.map { $0.y }.max() ?? 1

        let width = max(maxX - minX, 1)
        let height = max(maxY - minY, 1)

        let normalizedPoints = drawnPoints.map { point in
            CGPoint(
                x: (point.x - minX) / width,
                y: (point.y - minY) / height
            )
        }

        let animationPath = AnimationPath(
            type: .bezier,
            points: normalizedPoints,
            curveType: normalizedPoints.count <= 4 ? .quadratic : .cubic
        )

        onComplete(animationPath)
        dismiss()
    }

    private func loadPresetPath(_ type: PathType) {
        // Generate preset points in canvas coordinates
        let center = CGPoint(x: 200, y: 300)
        let radius: CGFloat = 100

        switch type {
        case .circular:
            // Circle path (12 points)
            drawnPoints = (0..<12).map { i in
                let angle = (CGFloat(i) / 12) * 2 * .pi
                return CGPoint(
                    x: center.x + radius * cos(angle),
                    y: center.y + radius * sin(angle)
                )
            }

        case .wave:
            // Wave path
            drawnPoints = (0...20).map { i in
                let x = CGFloat(i) * 20
                let y = center.y + sin(CGFloat(i) * 0.5) * 50
                return CGPoint(x: x, y: y)
            }

        case .arc:
            // Arc path (quarter circle)
            drawnPoints = (0...10).map { i in
                let angle = (CGFloat(i) / 10) * (.pi / 2)
                return CGPoint(
                    x: center.x + radius * cos(angle),
                    y: center.y + radius * sin(angle)
                )
            }

        default:
            break
        }
    }
}

#endif
