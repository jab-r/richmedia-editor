//
// AnimationPresetPicker.swift
// RichmediaEditor
//
// Visual gallery for selecting animation presets
//

import SwiftUI

#if canImport(UIKit)

struct AnimationPresetPicker: View {
    @Binding var selectedPreset: AnimationPreset?
    let onSelect: (AnimationPreset) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    ForEach(AnimationCategory.allCases, id: \.self) { category in
                        presetSection(for: category)
                    }
                }
                .padding()
            }
            .navigationTitle("Animations")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func presetSection(for category: AnimationCategory) -> some View {
        let presets = AnimationPreset.allCases.filter { $0.category == category }

        if !presets.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text(category.rawValue)
                    .font(.headline)
                    .foregroundColor(.primary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(presets, id: \.self) { preset in
                            PresetThumbnail(
                                preset: preset,
                                isSelected: selectedPreset == preset,
                                onTap: {
                                    selectedPreset = preset
                                    onSelect(preset)
                                    dismiss()
                                }
                            )
                        }
                    }
                }
            }
        }
    }
}

/// Animated thumbnail preview for a preset
struct PresetThumbnail: View {
    let preset: AnimationPreset
    let isSelected: Bool
    let onTap: () -> Void

    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .frame(width: 100, height: 100)

                // Animated preview text
                previewText
            }
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 3)
            )

            Text(preset.displayName)
                .font(.caption)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 100)
        }
        .onTapGesture(perform: onTap)
        .onAppear {
            startAnimation()
        }
    }

    @ViewBuilder
    private var previewText: some View {
        let baseText = Text("Aa")
            .font(.system(size: 32, weight: .bold))
            .foregroundColor(.primary)

        switch preset {
        // Entrance
        case .fadeIn:
            baseText
                .opacity(isAnimating ? 1 : 0)
                .animation(.easeIn(duration: 1.0).repeatForever(), value: isAnimating)
        case .fadeSlideUp:
            baseText
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 20)
                .animation(.easeOut(duration: 1.0).repeatForever(), value: isAnimating)
        case .fadeSlideDown:
            baseText
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : -20)
                .animation(.easeOut(duration: 1.0).repeatForever(), value: isAnimating)
        case .fadeSlideLeft:
            baseText
                .opacity(isAnimating ? 1 : 0)
                .offset(x: isAnimating ? 0 : 20)
                .animation(.easeOut(duration: 1.0).repeatForever(), value: isAnimating)
        case .fadeSlideRight:
            baseText
                .opacity(isAnimating ? 1 : 0)
                .offset(x: isAnimating ? 0 : -20)
                .animation(.easeOut(duration: 1.0).repeatForever(), value: isAnimating)
        case .zoomIn:
            baseText
                .scaleEffect(isAnimating ? 1.0 : 0.5)
                .opacity(isAnimating ? 1 : 0)
                .animation(.easeOut(duration: 1.0).repeatForever(), value: isAnimating)
        case .bounceIn:
            baseText
                .scaleEffect(isAnimating ? 1.0 : 0)
                .animation(.spring(response: 0.6, dampingFraction: 0.6).repeatForever(), value: isAnimating)
        case .popIn:
            baseText
                .scaleEffect(isAnimating ? 1.0 : 0.3)
                .opacity(isAnimating ? 1 : 0)
                .animation(.spring(response: 0.6, dampingFraction: 0.7).repeatForever(), value: isAnimating)

        // Exit
        case .fadeOut:
            baseText
                .opacity(isAnimating ? 0 : 1)
                .animation(.easeOut(duration: 1.0).repeatForever(), value: isAnimating)
        case .slideOutUp:
            baseText
                .offset(y: isAnimating ? -20 : 0)
                .opacity(isAnimating ? 0 : 1)
                .animation(.easeIn(duration: 1.0).repeatForever(), value: isAnimating)
        case .slideOutDown:
            baseText
                .offset(y: isAnimating ? 20 : 0)
                .opacity(isAnimating ? 0 : 1)
                .animation(.easeIn(duration: 1.0).repeatForever(), value: isAnimating)
        case .zoomOut:
            baseText
                .scaleEffect(isAnimating ? 0.5 : 1.0)
                .opacity(isAnimating ? 0 : 1)
                .animation(.easeIn(duration: 1.0).repeatForever(), value: isAnimating)

        // Loop
        case .pulse:
            baseText
                .scaleEffect(isAnimating ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isAnimating)
        case .bounce:
            baseText
                .offset(y: isAnimating ? -10 : 0)
                .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: isAnimating)
        case .float:
            baseText
                .offset(y: isAnimating ? -8 : 8)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)
        case .wiggle:
            baseText
                .rotationEffect(.degrees(isAnimating ? 5 : -5))
                .animation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true), value: isAnimating)
        case .rotate:
            baseText
                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                .animation(.linear(duration: 2.0).repeatForever(autoreverses: false), value: isAnimating)

        // Path (placeholder)
        case .motionPath, .curvePath:
            baseText
        }
    }

    private func startAnimation() {
        withAnimation {
            isAnimating = true
        }
    }
}

/// Helper modifier for preview animations
struct PreviewModifier<Modified: View>: ViewModifier {
    let animation: Animation
    let modify: (AnyView) -> Modified

    func body(content: Content) -> some View {
        modify(AnyView(content))
            .animation(animation, value: UUID())
    }
}

#endif
