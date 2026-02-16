# Autoplay Implementation Plan

## Context

The richmedia format currently has no specification for automatic block advancement or transitions. Gallery posts display as manually-swipeable carousels with no timing behavior. The spec explicitly says auto-advance is "optional (not specified in the format — up to the renderer)." This plan adds autoplay as a first-class feature in the format spec, models, and player — enabling Instagram Stories-style playback where blocks auto-advance (with video blocks playing to completion) and transition effects between blocks.

---

## Design Decisions

- **Autoplay settings live at root level** (`RichPostContent.autoplay`) because it's a post-level presentation concern. Per-block `duration` overrides live on `RichPostBlock`.
- **All new fields are optional** — existing JSON without autoplay decodes identically (backward compatible).
- **Public API unchanged** — `GalleryPlayerView.init(content:localImages:)` stays the same; autoplay is purely data-driven from the `RichPostContent`.
- **TabView replacement** — `TabView(.page)` doesn't support custom transitions. Replace with a `ZStack`-based pager in `GalleryPlayerView` only (editor's `GalleryCanvasView` keeps its `TabView`).
- **Video blocks wait for completion** — instead of a timer, observe `AVPlayerItemDidPlayToEndTime` so HLS streams of unknown length work correctly.

---

## Phase 1: New Model — `AutoplaySettings.swift`

**New file:** `Sources/RichmediaEditor/Models/AutoplaySettings.swift`

```swift
public struct AutoplaySettings: Codable, Equatable, Sendable {
    public var enabled: Bool
    public var defaultBlockDuration: TimeInterval  // seconds, for image/text blocks (default 5.0)
    public var transition: BlockTransition
    public var endBehavior: AutoplayEndBehavior

    public init(enabled: Bool = true, defaultBlockDuration: TimeInterval = 5.0,
                transition: BlockTransition = BlockTransition(), endBehavior: AutoplayEndBehavior = .stop)
}

public struct BlockTransition: Codable, Equatable, Sendable {
    public var style: TransitionStyle      // default .fade
    public var duration: TimeInterval      // default 0.5
}

public enum TransitionStyle: String, Codable, Equatable, Sendable, CaseIterable {
    case none          // instant cut
    case fade          // crossfade (opacity)
    case slide         // horizontal slide
    case crossDissolve // fade + subtle zoom
}

public enum AutoplayEndBehavior: String, Codable, Equatable, Sendable {
    case stop   // pause on last block (default)
    case loop   // return to first block
}
```

## Phase 2: Model Changes — `RichPostContent.swift`

**Modify:** `Sources/RichmediaEditor/Models/RichPostContent.swift`

- Add `public var autoplay: AutoplaySettings?` to `RichPostContent` (+ `init` parameter with default `nil`)
- Add `public var duration: TimeInterval?` to `RichPostBlock` (+ `init` parameter with default `nil`)

Both optional, so `Codable` auto-synthesis handles backward compat.

## Phase 3: New Service — `VideoPlayerManager.swift`

**New file:** `Sources/RichmediaEditor/Services/VideoPlayerManager.swift`

`@MainActor final class VideoPlayerManager: ObservableObject` that wraps `AVPlayer` lifecycle:

- `loadVideo(url:)` — creates `AVPlayerItem`, observes `.status` for duration, registers `AVPlayerItemDidPlayToEndTime` notification
- `@Published videoDuration: TimeInterval?` — set when asset loads
- `@Published didFinishPlaying: Bool` — set on playback completion
- `play()`, `pause()`, `cleanup()` — lifecycle management
- Replaces the inline `AVPlayer(url:)` currently in `GalleryPlayerView.mediaView(for:)` (line 150)

Follows the caching pattern already in `MediaCanvasView.getOrCreatePlayer` (lines 238-242).

## Phase 4: New Service — `AutoplayEngine.swift`

**New file:** `Sources/RichmediaEditor/Services/AutoplayEngine.swift`

`@MainActor final class AutoplayEngine: ObservableObject` — drives block-level timing:

- `startBlock(block:settings:onVideoFinish:)` — starts countdown for current block
  - Video blocks (no explicit `duration`): wait for `didFinishPlaying` from `VideoPlayerManager`
  - Video blocks (explicit `duration`): use timer
  - Image/text blocks: use `block.duration ?? settings.defaultBlockDuration`
- `@Published shouldAdvance: Bool` — observed by view to trigger page change
- `cancel()` — stops any pending timer/observation
- Uses `Task.sleep` for timers (structured concurrency, auto-cancellation)

## Phase 5: Rewrite `GalleryPlayerView.swift`

**Modify:** `Sources/RichmediaEditor/Views/GalleryPlayerView.swift` (major rewrite)

### 5a. Replace TabView with ZStack-based pager

```
ZStack {
    // Outgoing block (during transition only)
    // Current block
}
.animation(transitionAnimation, value: currentPage)
.gesture(swipeGesture)  // DragGesture for manual swipe
```

Map `TransitionStyle` to SwiftUI transitions:
- `.none` → `.identity`
- `.fade` → `.opacity`
- `.slide` → `.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading))`
- `.crossDissolve` → `.opacity.combined(with: .scale(scale: 1.02))`

### 5b. Wire autoplay engine

- `@StateObject private var autoplayEngine = AutoplayEngine()`
- On `currentPage` change → `autoplayEngine.startBlock(...)`
- On `autoplayEngine.shouldAdvance` → advance page (respecting `endBehavior`)
- On `isPlaying` toggle → pause/resume engine
- When `autoplay` is nil → engine never starts, manual swipe only (same as today)

### 5c. Add progress bar overlay

Instagram Stories-style segmented progress bar at top (replaces capsule dots when autoplay is active):

```
HStack(spacing: 2) {
    ForEach blocks → Capsule with fill based on:
      - completed blocks: full white
      - current block: animated fill (progress 0→1)
      - future blocks: white @ 30% opacity
}
```

Driven by a `TimelineView` or `Timer.publish` updating `@State progress: CGFloat` at ~30fps.

### 5d. Extract `AutoplayBlockView` (internal)

Per-block view that owns a `VideoPlayerManager` for video blocks:
- Communicates `onVideoDidFinish` and `onVideoDurationLoaded` back to parent
- Handles `isPlaying` → play/pause video
- Cleanup on `onDisappear`

## Phase 6: Tests

**Modify:** `Tests/RichmediaEditorTests/RichmediaEditorTests.swift`

Add tests for:
- `AutoplaySettings` round-trip serialization
- `BlockTransition` serialization with all `TransitionStyle` cases
- `RichPostBlock.duration` override serialization
- Backward compatibility: JSON without `autoplay`/`duration` decodes correctly
- `AutoplayEndBehavior` enum values

## Phase 7: Format Spec Update

**Modify:** `../loxation-sw/docs/guide_to_richmedia_posts.md`

- Add `autoplay` row to `RichPostContent` table
- Add `duration` row to `RichPostBlock` table
- Add `AutoplaySettings` schema section (enabled, defaultBlockDuration, transition, endBehavior)
- Add `BlockTransition` schema section (style, duration)
- Add `TransitionStyle` enum values table (none, fade, slide, crossDissolve)
- Add `AutoplayEndBehavior` enum values table (stop, loop)
- Update "Gallery rendering" section to reference autoplay behavior
- Add validation rules: `defaultBlockDuration > 0`, `duration > 0`, `transition.duration >= 0`
- Add JSON example of a multi-block post with autoplay

---

## File Summary

| File | Action | Phase |
|------|--------|-------|
| `Sources/RichmediaEditor/Models/AutoplaySettings.swift` | NEW | 1 |
| `Sources/RichmediaEditor/Models/RichPostContent.swift` | MODIFY | 2 |
| `Sources/RichmediaEditor/Services/VideoPlayerManager.swift` | NEW | 3 |
| `Sources/RichmediaEditor/Services/AutoplayEngine.swift` | NEW | 4 |
| `Sources/RichmediaEditor/Views/GalleryPlayerView.swift` | REWRITE | 5 |
| `Tests/RichmediaEditorTests/RichmediaEditorTests.swift` | MODIFY | 6 |
| `../loxation-sw/docs/guide_to_richmedia_posts.md` | MODIFY | 7 |

**Unchanged:** `AnimatedPostEditorView`, `GalleryCanvasView`, `MediaCanvasView`, `AnimatedPostEditorViewModel`, all other model files.

---

## Verification

1. `swift build` — confirm package compiles with new models and rewritten view
2. `swift test` — confirm existing tests pass + new autoplay serialization tests pass
3. Manual test: Create a `RichPostContent` with `autoplay: AutoplaySettings(enabled: true)` and 3 image blocks → verify GalleryPlayerView auto-advances with fade transitions and progress bar
4. Manual test: Create a post with a video block → verify it plays to completion before advancing
5. Manual test: Create a post without `autoplay` field → verify manual swipe still works identically to current behavior
6. Manual test: Verify `endBehavior: .loop` returns to first block after last, `.stop` pauses on last
