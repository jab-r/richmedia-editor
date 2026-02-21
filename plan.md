# Apple Music Preview Player — Implementation Plan

## Overview

Add the ability to attach an Apple Music song to a richmedia post. The editor gets a "Music" toolbar button that opens a search sheet. Users search by song name, see results with artwork/artist/title, tap to select, and a 30-second preview loops in the background during editing/playback. The song reference is persisted in the JSON document so the viewer (`GalleryPlayerView`) can also play it.

---

## 1. Model Layer

### New model: `MusicTrack.swift` (in `Models/`)

```swift
public struct MusicTrack: Codable, Equatable, Sendable {
    public var trackName: String        // "Bohemian Rhapsody"
    public var artistName: String       // "Queen"
    public var albumName: String?       // "A Night at the Opera"
    public var previewURL: String       // 30-sec AAC preview URL from Apple Music API
    public var artworkURL: String?      // Album artwork URL (100x100 or similar)
    public var appleMusicID: String     // Apple Music track ID (for deep-linking)
}
```

### Model changes: `RichPostContent.swift`

Add an optional `musicTrack` field at the **post level** (not per-block — music plays across the entire post):

```swift
public struct RichPostContent {
    public var version: Int
    public var blocks: [RichPostBlock]
    public var musicTrack: MusicTrack?    // ← NEW
}
```

**Rationale — post-level vs block-level:** Music is a background track for the whole post (like Instagram Reels). It doesn't make sense per-block since it loops continuously as the user swipes through a gallery. One track per post keeps the UX simple.

---

## 2. Service Layer

### New service: `AppleMusicSearchService.swift` (in `Services/`)

Uses the **Apple Music API (MusicKit)** via the `MusicKit` framework (available iOS 15.4+, no API key needed for on-device search):

```swift
@MainActor
class AppleMusicSearchService: ObservableObject {
    @Published var results: [MusicTrack] = []
    @Published var isSearching = false
    @Published var authorizationStatus: MusicAuthorization.Status

    func requestAuthorization() async
    func search(query: String) async    // Debounced, calls MusicCatalogSearchRequest
}
```

Key details:
- Uses `MusicCatalogSearchRequest` (MusicKit) — searches Apple's catalog, returns songs with `.previewAssets` containing the 30-sec preview URL
- No developer token needed — MusicKit uses the device's Apple Music entitlement
- Debounce search input (~400ms) to avoid excessive API calls
- Map MusicKit `Song` objects → our `MusicTrack` model
- Handle authorization: `MusicAuthorization.request()` — user sees a one-time permission prompt

### New service: `PreviewAudioPlayer.swift` (in `Services/`)

Handles looping playback of the 30-sec preview:

```swift
@MainActor
class PreviewAudioPlayer: ObservableObject {
    @Published var isPlaying = false
    @Published var currentTrack: MusicTrack?

    func play(_ track: MusicTrack)      // Start/restart playback
    func pause()
    func resume()
    func stop()                         // Stop + reset
}
```

Key details:
- Uses `AVPlayer` with the preview URL (standard HTTP AAC stream)
- Configures `AVAudioSession` for `.playback` category so audio mixes properly
- Loops via `NotificationCenter` observer on `.AVPlayerItemDidPlayToEndTime` → seek to zero and replay
- Cleans up player on `stop()` / view disappear

---

## 3. ViewModel Changes

### `AnimatedPostEditorViewModel`

Add:
```swift
@Published public var musicTrack: MusicTrack?    // Currently attached track

public func setMusicTrack(_ track: MusicTrack?)  // Set or clear
```

Update `richContent` computed property to include `musicTrack`:
```swift
public var richContent: RichPostContent {
    RichPostContent(version: 1, blocks: blocks, musicTrack: musicTrack)
}
```

Update `loadContent()` to restore `musicTrack` from existing content.

---

## 4. View Layer

### New view: `MusicSearchView.swift` (in `Views/`)

Presented as a `.sheet` from the editor. UI structure:

```
┌─────────────────────────────┐
│  ♫ Add Music          Done  │  ← Navigation bar
├─────────────────────────────┤
│  🔍 Search songs...         │  ← Search bar
├─────────────────────────────┤
│  ┌────┐                     │
│  │ 🎵 │ Song Title          │  ← Result row: artwork + title
│  │    │ Artist Name    ▶    │     + artist + preview button
│  └────┘                     │
│  ┌────┐                     │
│  │ 🎵 │ Another Song        │
│  │    │ Another Artist ▶    │
│  └────┘                     │
│         ...                 │
├─────────────────────────────┤
│  Currently selected:        │  ← Shows current selection
│  "Song Title" — Artist  ✕   │     with remove button
└─────────────────────────────┘
```

Features:
- `TextField` with `.searchable` style for song query input
- Debounced search (400ms delay after typing stops)
- `List` of results: each row shows 50x50 artwork thumbnail (via `AsyncImage`), track name, artist name, and a preview play/pause button
- Tapping a row selects it → calls `viewModel.setMusicTrack(track)` → dismisses sheet
- Preview button on each row plays/pauses the 30-sec clip so user can audition before selecting
- "Currently selected" bar at bottom if a track is already set, with an "✕" remove button
- Authorization prompt handled gracefully: if MusicKit not authorized, show a message with a "Grant Access" button

### Editor toolbar changes: `AnimatedPostEditorView.swift`

Add a "Music" button between "Lottie" and "Help" in the bottom toolbar:

```swift
Button(action: { showMusicPicker = true }) {
    VStack(spacing: 4) {
        Image(systemName: "music.note")
            .font(.title2)
            .foregroundStyle(.pink.gradient)  // Pink for music
        Text("Music")
            .font(.caption2)
    }
}
.disabled(viewModel.blocks.isEmpty)
```

Add `@State private var showMusicPicker = false` and a `.sheet(isPresented: $showMusicPicker)` presenting `MusicSearchView`.

### Music indicator in editor

When a track is selected, show a small floating indicator (pill) near the top of the canvas:
```
┌──────────────────────────────┐
│ ♫ "Song Title" — Artist   ✕ │
└──────────────────────────────┘
```
- `.ultraThinMaterial` background (glass morphism, consistent with existing UI)
- Tap to re-open the music picker
- "✕" to remove the track

### Audio playback in editor

- When `isPlaying == true` (play mode), start the preview audio loop
- When `isPlaying == false` (edit mode), pause audio
- Ties into existing `viewModel.togglePlayback()` flow

---

## 5. GalleryPlayerView Changes

The viewer needs to play the music track too:

- Read `content.musicTrack` on appear
- Create a `PreviewAudioPlayer` instance
- Start looping playback on appear, stop on disappear
- Respect the existing play/pause toggle

---

## 6. Package.swift

Add MusicKit framework dependency. MusicKit is a system framework (no SPM package needed), but we need:
```swift
platforms: [.iOS(.v16), .macOS(.v13)]  // Already compatible
```
Just `import MusicKit` in the relevant files. No external dependency additions needed.

**Note:** macOS 13+ supports MusicKit too, so cross-platform compatibility is maintained.

---

## 7. Files to Create/Modify

| Action | File | What |
|--------|------|------|
| **Create** | `Models/MusicTrack.swift` | New model |
| **Create** | `Services/AppleMusicSearchService.swift` | MusicKit search |
| **Create** | `Services/PreviewAudioPlayer.swift` | AVPlayer looping playback |
| **Create** | `Views/MusicSearchView.swift` | Search + select UI |
| **Modify** | `Models/RichPostContent.swift` | Add `musicTrack` field |
| **Modify** | `ViewModels/AnimatedPostEditorViewModel.swift` | Add `musicTrack` state + methods |
| **Modify** | `Views/AnimatedPostEditorView.swift` | Music toolbar button + sheet + indicator |
| **Modify** | `Views/GalleryPlayerView.swift` | Play music on view |

---

## 8. Design Decisions & Trade-offs

1. **MusicKit vs iTunes Search API**: MusicKit is the right choice — it's on-device, doesn't need a developer token for catalog search, and provides preview URLs directly. The iTunes Search API is an alternative but requires network requests to a REST endpoint and is considered legacy.

2. **Post-level vs block-level music**: Post-level. Music is a continuous background track, not tied to individual slides. This matches Instagram/TikTok behavior.

3. **Preview URL persistence**: We store the preview URL string in the JSON. Preview URLs are temporary (they expire), but they're long-lived enough for local editing. The `appleMusicID` field allows the host app or server to re-resolve the preview URL if needed for long-term storage.

4. **Audio session**: Use `.playback` category with `.mixWithOthers` option so the preview doesn't interrupt other audio unexpectedly during editing. In play mode, use `.duckOthers` to lower other audio.

5. **No streaming of full songs**: We only use the free 30-sec preview. No Apple Music subscription required. This keeps it simple and avoids licensing complexity.

6. **Format spec**: The `musicTrack` field needs to be documented in the format spec (host repo). This is noted but the spec file doesn't exist in this repo.
