//
// AnimationRenderer.swift
// RichmediaEditor
//
// Executes animations on text layers using SwiftUI animations + CAKeyframeAnimation
//

import SwiftUI

#if canImport(UIKit)

/// Service for rendering text layer animations
public enum AnimationRenderer {

    /// Apply animation to a view based on text layer configuration
    public static func animated<Content: View>(
        layer: TextLayer,
        content: Content
    ) -> some View {
        AnimatedTextLayerView(layer: layer, content: content)
    }
}

/// View modifier that applies animations to text layers
private struct AnimatedTextLayerView<Content: View>: View {
    let layer: TextLayer
    let content: Content

    @State private var isAnimating = false
    @State private var animationCycle = 0
    @State private var hueRotation: Double = 0
    @State private var flashPhase = false
    @State private var typewriterCount = 0

    var body: some View {
        Group {
            if let animation = layer.animation {
                animatedContent(animation: animation)
            } else {
                content
            }
        }
    }

    @ViewBuilder
    private func animatedContent(animation: TextAnimation) -> some View {
        switch animation.preset {
        // MARK: - Entrance Effects
        case .fadeIn:
            content
                .opacity(isAnimating ? 1 : 0)
                .onAppear {
                    withAnimation(.easeIn(duration: animation.duration).delay(animation.delay)) {
                        isAnimating = true
                    }
                }

        case .fadeSlideUp:
            content
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 50)
                .onAppear {
                    withAnimation(.easeOut(duration: animation.duration).delay(animation.delay)) {
                        isAnimating = true
                    }
                }

        case .fadeSlideDown:
            content
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : -50)
                .onAppear {
                    withAnimation(.easeOut(duration: animation.duration).delay(animation.delay)) {
                        isAnimating = true
                    }
                }

        case .fadeSlideLeft:
            content
                .opacity(isAnimating ? 1 : 0)
                .offset(x: isAnimating ? 0 : 50)
                .onAppear {
                    withAnimation(.easeOut(duration: animation.duration).delay(animation.delay)) {
                        isAnimating = true
                    }
                }

        case .fadeSlideRight:
            content
                .opacity(isAnimating ? 1 : 0)
                .offset(x: isAnimating ? 0 : -50)
                .onAppear {
                    withAnimation(.easeOut(duration: animation.duration).delay(animation.delay)) {
                        isAnimating = true
                    }
                }

        case .zoomIn:
            content
                .scaleEffect(isAnimating ? 1.0 : 0.5)
                .opacity(isAnimating ? 1 : 0)
                .onAppear {
                    withAnimation(.easeOut(duration: animation.duration).delay(animation.delay)) {
                        isAnimating = true
                    }
                }

        case .bounceIn:
            content
                .scaleEffect(isAnimating ? 1.0 : 0)
                .onAppear {
                    withAnimation(
                        .interpolatingSpring(stiffness: 170, damping: 10)
                        .delay(animation.delay)
                    ) {
                        isAnimating = true
                    }
                }

        case .popIn:
            content
                .scaleEffect(isAnimating ? 1.0 : 0.3)
                .opacity(isAnimating ? 1 : 0)
                .onAppear {
                    withAnimation(
                        .spring(response: 0.6, dampingFraction: 0.7)
                        .delay(animation.delay)
                    ) {
                        isAnimating = true
                    }
                }

        // MARK: - Exit Effects
        case .fadeOut:
            content
                .opacity(isAnimating ? 0 : 1)
                .onAppear {
                    withAnimation(.easeOut(duration: animation.duration).delay(animation.delay)) {
                        isAnimating = true
                    }
                }

        case .slideOutUp:
            content
                .offset(y: isAnimating ? -50 : 0)
                .opacity(isAnimating ? 0 : 1)
                .onAppear {
                    withAnimation(.easeIn(duration: animation.duration).delay(animation.delay)) {
                        isAnimating = true
                    }
                }

        case .slideOutDown:
            content
                .offset(y: isAnimating ? 50 : 0)
                .opacity(isAnimating ? 0 : 1)
                .onAppear {
                    withAnimation(.easeIn(duration: animation.duration).delay(animation.delay)) {
                        isAnimating = true
                    }
                }

        case .zoomOut:
            content
                .scaleEffect(isAnimating ? 0.5 : 1.0)
                .opacity(isAnimating ? 0 : 1)
                .onAppear {
                    withAnimation(.easeIn(duration: animation.duration).delay(animation.delay)) {
                        isAnimating = true
                    }
                }

        // MARK: - Looping Effects
        case .pulse:
            content
                .scaleEffect(isAnimating ? 1.1 : 1.0)
                .onAppear {
                    scheduleLoopingAnimation(animation: animation) {
                        withAnimation(
                            .easeInOut(duration: animation.duration)
                        ) {
                            isAnimating.toggle()
                        }
                    }
                }

        case .bounce:
            content
                .offset(y: isAnimating ? -10 : 0)
                .onAppear {
                    scheduleLoopingAnimation(animation: animation) {
                        withAnimation(
                            .easeInOut(duration: animation.duration)
                        ) {
                            isAnimating.toggle()
                        }
                    }
                }

        case .float:
            content
                .offset(y: isAnimating ? -8 : 8)
                .onAppear {
                    scheduleLoopingAnimation(animation: animation) {
                        withAnimation(
                            .easeInOut(duration: animation.duration)
                        ) {
                            isAnimating.toggle()
                        }
                    }
                }

        case .wiggle:
            content
                .rotationEffect(.degrees(isAnimating ? 5 : -5))
                .onAppear {
                    scheduleLoopingAnimation(animation: animation) {
                        withAnimation(
                            .easeInOut(duration: animation.duration)
                        ) {
                            isAnimating.toggle()
                        }
                    }
                }

        case .rotate:
            content
                .rotationEffect(.degrees(Double(animationCycle) * 360))
                .onAppear {
                    scheduleLoopingAnimation(animation: animation) {
                        withAnimation(
                            .linear(duration: animation.duration)
                        ) {
                            animationCycle += 1
                        }
                    }
                }

        case .glow:
            content
                .shadow(color: .white.opacity(isAnimating ? 0.8 : 0), radius: isAnimating ? 12 : 0)
                .onAppear {
                    scheduleLoopingAnimation(animation: animation) {
                        withAnimation(
                            .easeInOut(duration: animation.duration)
                        ) {
                            isAnimating.toggle()
                        }
                    }
                }

        case .shake:
            content
                .offset(x: isAnimating ? 3 : -3)
                .onAppear {
                    scheduleLoopingAnimation(animation: animation) {
                        withAnimation(
                            .easeInOut(duration: animation.duration * 0.15)
                        ) {
                            isAnimating.toggle()
                        }
                    }
                }

        case .heartbeat:
            content
                .scaleEffect(isAnimating ? 1.15 : 1.0)
                .onAppear {
                    scheduleLoopingAnimation(animation: animation) {
                        // First pump
                        withAnimation(.easeInOut(duration: animation.duration * 0.15)) {
                            isAnimating = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + animation.duration * 0.15) {
                            withAnimation(.easeInOut(duration: animation.duration * 0.15)) {
                                isAnimating = false
                            }
                        }
                        // Second pump
                        DispatchQueue.main.asyncAfter(deadline: .now() + animation.duration * 0.35) {
                            withAnimation(.easeInOut(duration: animation.duration * 0.15)) {
                                isAnimating = true
                            }
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + animation.duration * 0.5) {
                            withAnimation(.easeInOut(duration: animation.duration * 0.15)) {
                                isAnimating = false
                            }
                        }
                    }
                }

        case .colorCycle:
            content
                .hueRotation(.degrees(hueRotation))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + animation.delay) {
                        withAnimation(.linear(duration: animation.duration).repeatForever(autoreverses: false)) {
                            hueRotation = 360
                        }
                    }
                }

        case .swing:
            content
                .rotationEffect(.degrees(isAnimating ? 8 : -8), anchor: .top)
                .onAppear {
                    scheduleLoopingAnimation(animation: animation) {
                        withAnimation(
                            .easeInOut(duration: animation.duration)
                        ) {
                            isAnimating.toggle()
                        }
                    }
                }

        case .flash:
            content
                .opacity(flashPhase ? 0 : 1)
                .onAppear {
                    scheduleLoopingAnimation(animation: animation) {
                        withAnimation(.easeInOut(duration: animation.duration * 0.1)) {
                            flashPhase = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + animation.duration * 0.25) {
                            withAnimation(.easeInOut(duration: animation.duration * 0.1)) {
                                flashPhase = false
                            }
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + animation.duration * 0.5) {
                            withAnimation(.easeInOut(duration: animation.duration * 0.1)) {
                                flashPhase = true
                            }
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + animation.duration * 0.75) {
                            withAnimation(.easeInOut(duration: animation.duration * 0.1)) {
                                flashPhase = false
                            }
                        }
                    }
                }

        // MARK: - Additional Entrance Effects
        case .typewriter:
            TypewriterView(
                text: layer.text,
                content: content,
                duration: animation.duration,
                delay: animation.delay
            )

        case .blurIn:
            content
                .blur(radius: isAnimating ? 0 : 20)
                .opacity(isAnimating ? 1 : 0)
                .onAppear {
                    withAnimation(.easeOut(duration: animation.duration).delay(animation.delay)) {
                        isAnimating = true
                    }
                }

        case .flipInX:
            content
                .rotation3DEffect(
                    .degrees(isAnimating ? 0 : 90),
                    axis: (x: 1, y: 0, z: 0),
                    perspective: 0.5
                )
                .opacity(isAnimating ? 1 : 0)
                .onAppear {
                    withAnimation(.easeOut(duration: animation.duration).delay(animation.delay)) {
                        isAnimating = true
                    }
                }

        case .flipInY:
            content
                .rotation3DEffect(
                    .degrees(isAnimating ? 0 : 90),
                    axis: (x: 0, y: 1, z: 0),
                    perspective: 0.5
                )
                .opacity(isAnimating ? 1 : 0)
                .onAppear {
                    withAnimation(.easeOut(duration: animation.duration).delay(animation.delay)) {
                        isAnimating = true
                    }
                }

        // MARK: - Additional Exit Effects
        case .blurOut:
            content
                .blur(radius: isAnimating ? 20 : 0)
                .opacity(isAnimating ? 0 : 1)
                .onAppear {
                    withAnimation(.easeIn(duration: animation.duration).delay(animation.delay)) {
                        isAnimating = true
                    }
                }

        case .shrinkOut:
            content
                .scaleEffect(isAnimating ? 0 : 1.0)
                .opacity(isAnimating ? 0 : 1)
                .onAppear {
                    withAnimation(.easeIn(duration: animation.duration).delay(animation.delay)) {
                        isAnimating = true
                    }
                }

        // MARK: - Path-based Animations
        case .motionPath, .curvePath:
            if let path = layer.path {
                PathAnimatedView(
                    content: content,
                    path: path,
                    duration: animation.duration,
                    delay: animation.delay
                )
            } else {
                // Fallback if no path defined
                content
            }
        }
    }

    /// Schedule looping animation with delay between cycles
    private func scheduleLoopingAnimation(animation: TextAnimation, perform: @escaping () -> Void) {
        // Initial delay
        DispatchQueue.main.asyncAfter(deadline: .now() + animation.delay) {
            performLoop(animation: animation, perform: perform)
        }
    }

    private func performLoop(animation: TextAnimation, perform: @escaping () -> Void) {
        perform()

        if animation.loop {
            let nextDelay = animation.duration + animation.loopDelay
            DispatchQueue.main.asyncAfter(deadline: .now() + nextDelay) {
                performLoop(animation: animation, perform: perform)
            }
        }
    }
}

/// View that reveals text one character at a time (typewriter effect)
private struct TypewriterView<Content: View>: View {
    let text: String
    let content: Content
    let duration: TimeInterval
    let delay: TimeInterval

    @State private var visibleCount = 0

    var body: some View {
        content
            .mask(
                HStack(spacing: 0) {
                    Text(String(text.prefix(visibleCount)))
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            )
            .onAppear {
                let charCount = text.count
                guard charCount > 0 else { return }
                let interval = duration / Double(charCount)
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    for i in 1...charCount {
                        DispatchQueue.main.asyncAfter(deadline: .now() + interval * Double(i)) {
                            visibleCount = i
                        }
                    }
                }
            }
    }
}

#endif
