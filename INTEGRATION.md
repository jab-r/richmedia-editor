# Integration with Loxation

This document describes how RichmediaEditor leverages existing Loxation facilities and patterns.

## Video/Audio Facilities from Loxation

### 1. VideoThumbnailGenerator (loxation/Utils/VideoThumbnailGenerator.swift)

**Pattern**: Actor-based thumbnail caching with AVAssetImageGenerator

**Loxation implementation**:
```swift
private actor ThumbnailCache {
    private var cache: [URL: PlatformImage] = [:]
}

static func generateThumbnail(for url: URL, completion: @escaping @Sendable (PlatformImage?) -> Void) {
    Task {
        // Check cache first
        if let cached = await cache.get(url) { ... }

        // Generate on background thread
        let asset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.maximumSize = CGSize(width: 600, height: 600)
        let time = CMTime(seconds: 0.5, preferredTimescale: 600)
        let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
    }
}
```

**How we'll use it**:
- RichmediaEditor's `MediaCanvasView` will delegate to Loxation's `VideoThumbnailGenerator` for video thumbnails
- No need to duplicate thumbnail generation logic
- Reuse the actor-based cache for performance

**Integration point**:
```swift
// In MediaCanvasView.swift (future implementation)
import VideoThumbnailGenerator  // From Loxation

// When displaying video block
VideoThumbnailGenerator.generateThumbnail(for: videoURL) { thumbnail in
    self.thumbnailImage = thumbnail
}
```

### 2. AVPlayer/VideoPlayer Pattern (FullscreenMediaViewer.swift, LiveStreamViewer.swift)

**Pattern**: SwiftUI VideoPlayer with AVPlayer state management

**Loxation implementation**:
```swift
@State private var player: AVPlayer?

// Lazy player initialization
private func getOrCreatePlayer(url: URL) -> AVPlayer {
    if let existing = player {
        return existing
    }
    let newPlayer = AVPlayer(url: url)
    player = newPlayer
    return newPlayer
}

// Cleanup on dismiss
.onDisappear {
    player?.pause()
    player = nil
}
```

**How we'll use it**:
- `MediaCanvasView` (video mode) will use same lazy initialization pattern
- `AnimatedPostPlayerView` will manage AVPlayer lifecycle identically
- Cleanup on view dismissal to prevent memory leaks

**Integration point**:
```swift
// In MediaCanvasView.swift (video rendering)
VideoPlayer(player: getOrCreatePlayer(url: videoURL)) {
    // Text layer overlays
    ForEach(textLayers) { layer in
        TextLayerView(layer: layer, playbackTime: player?.currentTime())
    }
}
```

### 3. MediaPicker Pattern (MediaPicker.swift)

**Pattern**: PHPickerViewController wrapper with multi-selection and async loading

**Loxation implementation**:
```swift
enum PickedMedia {
    case image(UIImage)
    case video(URL, thumbnail: UIImage?)
}

struct PHMediaPicker: UIViewControllerRepresentable {
    let onMediaPicked: ([PickedMedia]) -> Void

    // Config: .any(of: [.images, .videos]), selectionLimit: 10
    // Async loading with withCheckedContinuation
    // Video: copy to temp, generate thumbnail
}
```

**How we'll use it**:
- RichmediaEditor will **delegate media picking to Loxation** entirely
- Loxation's `PublicPostComposerView` will call `AnimatedPostEditorView` AFTER media selection
- RichmediaEditor receives `MediaInput.image(UIImage)` or `.video(URL)` as initialMedia

**Integration flow**:
```
User taps "New Animated Post"
  ↓
Loxation shows PHMediaPicker
  ↓
User selects photo/video
  ↓
Loxation passes to AnimatedPostEditorView(initialMedia: .image(uiImage))
  ↓
RichmediaEditor opens with media already loaded
```

**Why this pattern**: Keeps RichmediaEditor decoupled from PhotosUI; Loxation handles all OS permissions, multi-selection logic, and temp file management.

### 4. 9:16 Aspect Ratio (Instagram Stories Format)

**Pattern**: `.aspectRatio(9/16, contentMode: .fit)`

**Loxation usage**: Not explicitly enforced in existing code, but standard for Stories/TikTok-style posts.

**How we'll use it**:
```swift
// In MediaCanvasView.swift
ZStack {
    // Media background
    AsyncImage(url: mediaURL) { ... }
        .scaledToFit()

    // Text overlays
    ForEach(textLayers) { ... }
}
.aspectRatio(9/16, contentMode: .fit)  // Instagram Stories ratio
```

---

## Xcode 26 / Swift 6 Concurrency

### Swift 6 Concurrency Requirements

**Sendable conformance**: All public models are `Codable` which implies `Sendable` when all properties are value types (String, Int, CGFloat, etc.). Our models already conform.

**@MainActor isolation**:
- `AnimatedPostEditorViewModel` is `@MainActor` (UI state)
- `AnimatedPostEditorView` is implicitly `@MainActor` (View protocol)
- Services (future `AnimationRenderer`, `VideoCompositor`) will be `actor` or nonisolated

**Actor pattern for thumbnail caching** (borrowed from Loxation):
```swift
// Future: AnimationRenderer.swift
private actor RenderCache {
    private var cache: [UUID: CAAnimation] = [:]

    func get(_ id: UUID) -> CAAnimation? { cache[id] }
    func set(_ id: UUID, animation: CAAnimation) { cache[id] = animation }
}
```

### Swift Package Manifest (Already Updated)

`Package.swift` specifies `swift-tools-version: 5.9` which supports Swift 6 language mode:

```swift
platforms: [
    .iOS(.v16),
    .macOS(.v13)
]
```

When Loxation imports RichmediaEditor, it will compile with Swift 6 strict concurrency checking enabled.

---

## Integration Checklist

### Phase 1: Foundation (Current)
- [x] Data models with Sendable conformance
- [x] Basic editor view structure
- [x] ViewModel with @MainActor isolation
- [ ] Integrate Loxation's VideoThumbnailGenerator for video previews
- [ ] Adopt Loxation's AVPlayer lazy initialization pattern

### Phase 2: Media Handling
- [ ] Loxation passes `MediaInput` to RichmediaEditor (no duplicate PHPicker)
- [ ] Video thumbnail generation via `VideoThumbnailGenerator.generateThumbnail`
- [ ] Image caching (reuse AsyncImage, no custom cache needed)

### Phase 3: Video Playback
- [ ] `MediaCanvasView` uses Loxation's VideoPlayer pattern
- [ ] AVPlayer lifecycle management (pause on background, cleanup on dismiss)
- [ ] Text overlay rendering on top of VideoPlayer

### Phase 4: Upload Integration
- [ ] Loxation's `PostMediaService` handles all uploads
- [ ] RichmediaEditor returns `RichPostContent` JSON only
- [ ] Loxation submits to API with uploaded media URLs

---

## Example Integration Code (Loxation Side)

### In PublicPostComposerView.swift (Loxation)

```swift
import RichmediaEditor

struct PublicPostComposerView: View {
    @State private var showAnimatedEditor = false
    @State private var selectedMedia: PickedMedia?

    var body: some View {
        // ... existing UI

        Button("Create Animated Post") {
            // Show media picker first
            showMediaPicker = true
        }
        .sheet(isPresented: $showMediaPicker) {
            PHMediaPicker { pickedItems in
                guard let firstItem = pickedItems.first else { return }

                // Convert to MediaInput
                switch firstItem {
                case .image(let uiImage):
                    selectedMedia = .image(uiImage)
                case .video(let url, _):
                    selectedMedia = .video(url)
                }

                showMediaPicker = false
                showAnimatedEditor = true
            }
        }
        .sheet(isPresented: $showAnimatedEditor) {
            if let media = selectedMedia {
                AnimatedPostEditorView(
                    initialMedia: convertToMediaInput(media),
                    onComplete: { richContent in
                        Task {
                            // Upload media via PostMediaService
                            let uploadResult = await uploadMediaFromRichContent(richContent)

                            // Submit to API
                            chatViewModel.addPublicPost(
                                "",
                                messageId: UUID().uuidString,
                                richContent: richContent
                            )
                        }
                        showAnimatedEditor = false
                    },
                    onCancel: {
                        showAnimatedEditor = false
                    }
                )
            }
        }
    }

    private func convertToMediaInput(_ picked: PickedMedia) -> RichmediaEditor.MediaInput {
        switch picked {
        case .image(let img):
            return .image(img)
        case .video(let url, _):
            return .video(url)
        }
    }
}
```

---

## Dependencies

RichmediaEditor has **zero external dependencies** in its `Package.swift`. All integration happens at Loxation's app level:

**Loxation provides**:
- Media picking (PHMediaPicker)
- Video thumbnail generation (VideoThumbnailGenerator)
- Upload infrastructure (PostMediaService)
- API submission (ChatViewModel)

**RichmediaEditor provides**:
- Text layer editing UI
- Animation presets
- JSON output (RichPostContent)
- HTML export

This keeps the package lightweight and reusable.

---

## Future: Shared Utilities Package

If VideoThumbnailGenerator becomes useful across multiple packages, consider:

```swift
// Hypothetical: LoxationShared package
.package(path: "../loxation-shared")

// RichmediaEditor/Package.swift
dependencies: [
    .product(name: "LoxationShared", package: "loxation-shared")
]
```

For now, Loxation app links both RichmediaEditor and its own utilities, bridging them at the app layer.
