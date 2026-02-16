# Plan: Block Thumbnail Strip for Reorder & Delete

## Context

The editor supports multi-block posts (gallery/carousel) but has no way to reorder or delete individual blocks. The ViewModel already has `deleteBlock` and `moveBlocks` methods — they just need UI. The user wants a thumbnail strip/grid that appears on demand (not always visible), is hidden during Play mode, and allows drag-to-reorder, tap-to-navigate, and tap-X-to-delete (no confirmation).

## Files to Change

| File | Action |
|------|--------|
| `Sources/RichmediaEditor/Views/BlockThumbnailStripView.swift` | **CREATE** — new view with `BlockThumbnailStripView`, `BlockThumbnailView`, `BlockDropDelegate` |
| `Sources/RichmediaEditor/Views/AnimatedPostEditorView.swift` | **MODIFY** — add toggle button + conditional strip in `editorContentView` |
| `Sources/RichmediaEditor/Views/GalleryCanvasView.swift` | **MODIFY** — add two-way `selectedBlockId` ↔ `currentPage` sync |

No model or ViewModel changes needed. Reuses existing `deleteBlock`, `moveBlocks`, `selectBlock`.

## Implementation

### 1. New file: `BlockThumbnailStripView.swift`

**`BlockThumbnailStripView`** — horizontal `ScrollView` with `LazyHStack` of thumbnails:
- Interface: `blocks`, `selectedBlockId`, `localImages`, `onSelect`, `onDelete`, `onMove`
- `ScrollViewReader` auto-scrolls to selected block
- Each item has `.onDrag` / `.onDrop` for reorder via `BlockDropDelegate`
- `.ultraThinMaterial` background, ~72pt height
- Only renders `#if canImport(UIKit)`

**`BlockThumbnailView`** — single thumbnail cell:
- 44pt wide × ~78pt tall (9:16 ratio)
- Shows local image via `Image(uiImage:)`, remote image via `AsyncImage`, or placeholder
- Video blocks get a small play icon badge (SF Symbol `play.fill`)
- Blue border + shadow when selected
- "X" delete button (`xmark.circle.fill`) in top-right corner, only when `blocks.count > 1`
- Direct delete on tap (no confirmation)

**`BlockDropDelegate`** — `DropDelegate` for reorder:
- Tracks `draggedBlockId` via `@Binding`
- On `dropEntered`, calls `onMove(IndexSet, Int)` with animation
- Maps to existing `viewModel.moveBlocks(from:to:)`

### 2. Modify `AnimatedPostEditorView.swift`

Add state:
```swift
@State private var showBlockStrip = false
```

In `editorContentView`, insert between `galleryView` and `Divider`:
```swift
if showBlockStrip && viewModel.blocks.count > 1 {
    BlockThumbnailStripView(...)
        .transition(.move(edge: .bottom).combined(with: .opacity))
}
```

Add a "Blocks" toggle button to `editorToolbar` (between Play and Media):
- Icon: `square.grid.2x2` when strip is hidden, `square.grid.2x2.fill` when shown
- Label: "Blocks"
- Only enabled when `blocks.count > 1`
- Toggles `showBlockStrip` with animation

Hide strip during Play mode:
```swift
.onChange(of: viewModel.isPlaying) { playing in
    if playing { showBlockStrip = false }
}
```

When blocks drop to 1, auto-hide:
```swift
.onChange(of: viewModel.blocks.count) { count in
    if count <= 1 { showBlockStrip = false }
}
```

### 3. Modify `GalleryCanvasView.swift`

Add two-way sync — when `selectedBlockId` changes externally (from thumbnail tap), update `currentPage`:
```swift
.onChange(of: selectedBlockId) { newId in
    if let newId, let index = blocks.firstIndex(where: { $0.id == newId }), index != currentPage {
        withAnimation { currentPage = index }
    }
}
```

Add reorder-aware sync — when block order changes but count doesn't:
```swift
.onChange(of: blocks.map(\.id)) { newIds in
    if let selectedId = selectedBlockId, let index = newIds.firstIndex(of: selectedId) {
        currentPage = index
    }
}
```

## Verification

1. **Build**: `swift build` or `xcodebuild -scheme RichmediaEditor -destination 'generic/platform=iOS Simulator' build`
2. **Manual testing in host app**:
   - Add 2+ media items → "Blocks" button becomes enabled in toolbar
   - Tap "Blocks" → thumbnail strip slides in with animation
   - Tap a thumbnail → main canvas navigates to that block
   - Long-press and drag a thumbnail → reorder with animation, canvas follows
   - Tap X on a thumbnail → block deleted immediately, strip updates
   - Delete down to 1 block → strip auto-hides, "Blocks" button disables
   - Tap Play → strip hides automatically
   - Add more media while strip is visible → new thumbnail appears at end
