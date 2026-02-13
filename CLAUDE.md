# RichmediaEditor - Project Instructions

## What This Is

A Swift Package (iOS 16+/macOS 13+) for creating locally-viewable richmedia documents with an Instagram/TikTok-style GUI editor. Users compose rich posts by adding text layers, animations, and Lottie overlays on top of photos and videos, then export as JSON.

## Build & Test

```bash
swift build          # Build the package
swift test           # Run all tests
```

Requires Xcode 15+ / Swift 5.9+. Single external dependency: Lottie 4.4+.

## Architecture

**MVVM + Services** with SwiftUI. Swift 6 concurrency compliant (@MainActor isolation, Sendable models).

```
Sources/RichmediaEditor/
├── Models/          # Codable data types (RichPostContent, TextLayer, TextAnimation, etc.)
├── Views/           # SwiftUI views (editor, canvas, pickers, overlays)
├── ViewModels/      # AnimatedPostEditorViewModel (@MainActor state)
├── Services/        # AnimationRenderer, PathAnimationRenderer, LottieImporter
├── Utilities/       # Extensions (ColorExtensions)
└── Resources/       # Bundled Lottie JSON templates
```

### Key Entry Point

`AnimatedPostEditorView` — the single public API view. Takes `MediaInput` (image/video), returns `RichPostContent` JSON via `onComplete` callback.

### Document Format

`RichPostContent` → JSON with `blocks[]`, each block has media reference + `textLayers[]` with position (normalized 0-1), style, animation preset, path, and optional Lottie overlay.

## Code Conventions

- All models are value types (structs) conforming to `Codable` and `Sendable`
- Positions use normalized coordinates (0.0–1.0) for device independence
- 9:16 aspect ratio (Instagram Stories format)
- Glass morphism UI with `.ultraThinMaterial` backgrounds
- Max 10 text layers per block
- SF Symbols for all icons

## Important Patterns

- **Local-first editing**: `localImages: [UUID: UIImage]` in ViewModel stores images before upload — supports UIImage directly, no URL required
- **Delegation to host app**: Media picking, uploading, and API submission are NOT handled here — the host app (Loxation) owns those responsibilities
- **Animation system**: 18 presets across entrance/exit/loop/path categories, rendered via `AnimationRenderer` (SwiftUI) and `PathAnimationRenderer` (CAKeyframeAnimation)

## Do NOT

- Add HTML export (intentionally skipped; server-side rendering handles it)
- Add media picker/upload logic (host app responsibility)
- Break the public API surface of `AnimatedPostEditorView`
