# RichmediaEditor - Project Instructions

## What This Is

A Swift Package (iOS 16+/macOS 13+) for creating locally-viewable richmedia documents with an Instagram/TikTok-style GUI editor. Users compose rich posts by adding text layers, animations, and Lottie overlays on top of photos and videos, with pinch-to-zoom/pan media positioning, then export as JSON. Documents are cross-platform (iOS/Android/web) — the canonical format spec lives at `../loxation-sw/docs/guide_to_richmedia_posts.md`.

## Build & Test

```bash
swift build          # Build the package
swift test           # Run all tests
```

For Xcode builds:
```bash
xcodebuild -scheme RichmediaEditor -destination 'generic/platform=iOS Simulator' build
```

Requires Xcode 15+ / Swift 5.9+. Single external dependency: Lottie 4.4+.

## Architecture

**MVVM + Services** with SwiftUI. Swift 6 concurrency compliant (@MainActor isolation, Sendable models).

```
Sources/RichmediaEditor/
├── Models/          # Codable data types (RichPostContent, TextLayer, MediaTransform, MusicTrack, etc.)
├── Views/           # SwiftUI views (editor, canvas, pickers, overlays, gallery player)
├── ViewModels/      # AnimatedPostEditorViewModel (@MainActor state)
├── Services/        # AnimationRenderer, PathAnimationRenderer, LottieImporter, AppleMusicSearchService, PreviewAudioPlayer
├── Utilities/       # Extensions (ColorExtensions)
└── Resources/       # Bundled Lottie JSON templates
```

### Key Entry Points

- `AnimatedPostEditorView` — the single public API editor view. Takes `MediaInput` (image/video), returns `RichPostContent` JSON via `onComplete` callback.
- `GalleryPlayerView` — read-only TikTok-style viewer for displaying animated posts. Takes `RichPostContent` and optional `localImages`.

### Document Format

`RichPostContent` → JSON with `blocks[]`, each block has media reference + `textLayers[]` with position (normalized 0-1), style, animation preset, path, optional Lottie overlay, and optional `mediaTransform` (zoom/pan state). Optional `musicTrack` at the root level for background Apple Music preview audio.

The canonical format specification is at `../loxation-sw/docs/guide_to_richmedia_posts.md`. Keep it in sync when adding/changing model fields.

## Code Conventions

- All models are value types (structs) conforming to `Codable` and `Sendable`
- Positions use normalized coordinates (0.0–1.0) for device independence
- 9:16 aspect ratio (Instagram Stories format)
- Glass morphism UI with `.ultraThinMaterial` backgrounds
- Max 10 text layers per block
- SF Symbols for all icons
- Color extensions: use `Color(hex:)` to init from hex string, `color.toHex()` to convert back (not `hexString`)

## Important Patterns

- **Canvas-first editing**: Tap text on canvas to select (blue border + floating toolbar), tap again to edit inline. No layer list — all interaction happens directly on the 9:16 canvas.
- **Edit/Play modes**: Edit mode enables gestures and selection; Play mode runs animations and disables interaction. Toggle via play/pause button.
- **Media transform**: Users pinch-to-zoom (1.0x–5.0x) and drag-to-pan background media. Stored as `MediaTransform` (scale, offsetX, offsetY) on each block. Images use `scaledToFill` with `.clipped()`.
- **Local-first editing**: `localImages: [UUID: UIImage]` in ViewModel stores images before upload — supports UIImage directly, no URL required.
- **Staggered layer positioning**: New text layers are placed at incrementally offset Y positions to avoid stacking.
- **Delegation to host app**: Media picking, uploading, and API submission are NOT handled here — the host app (Loxation) owns those responsibilities.
- **Animation system**: 18 presets across entrance/exit/loop/path categories, rendered via `AnimationRenderer` (SwiftUI) and `PathAnimationRenderer` (CAKeyframeAnimation). Picker is `AnimationPresetPicker`.

## Key Views

- `AnimatedPostEditorView` — main editor with bottom toolbar (media, text, lottie, play) and floating selected-layer toolbar
- `MediaCanvasView` — single block canvas with media background, gesture handling, and text layer overlays
- `GalleryCanvasView` — multi-block TabView for gallery/carousel editing
- `GalleryPlayerView` — read-only viewer with auto-play animations and background music playback
- `MusicSearchView` — Apple Music search picker for selecting background tracks
- `TextLayerOverlay` — inline-editable text with drag/pinch/rotate gestures (inside MediaCanvasView)

## Do NOT

- Add HTML export (intentionally skipped; server-side rendering handles it)
- Add media picker/upload logic (host app responsibility)
- Break the public API surface of `AnimatedPostEditorView` or `GalleryPlayerView`
- Modify model fields without updating the format spec at `../loxation-sw/docs/guide_to_richmedia_posts.md`
