# Request: add `flags` and `replyToId` to `RichPostContent`

**From:** loxation-android (Phase 2 public-post queueing work), parallel ask to richmedia-editor-android
**To:** richmedia-editor (Swift Package)
**Status:** Proposal — please review and ack before we land workarounds
**Tracking:** loxation-android Phase 2 public-post queue parity. Sibling doc lives at `../richmedia-editor-android/RICHMEDIA_PARITY_REQUEST.md`.

## TL;DR

Please add two optional top-level fields to `RichPostContent`:

```swift
public struct RichPostContent: Codable, Equatable {
    public var version: Int
    public var blocks: [RichPostBlock]
    public var musicTrack: MusicTrack?
    public var flags: [String]?      // ← new
    public var replyToId: String?    // ← new

    public static let contentType = "application/vnd.loxation.richmedia+json"
}
```

Both optional, both omitted from JSON when nil (so existing payloads decode unchanged and existing posts in the wild keep round-tripping). The editor UI does not need to do anything with them — they ride along as opaque metadata. We just need the editor's `RichPostContent` to **preserve them through encode/decode** so the consuming app can read/write them without a lossy conversion to a forked model.

## Why

`loxation/Models/RichPostContent.swift` (in `../loxation-sw`) is the **app-side** wire model. It carries the two fields:

```swift
struct RichPostContent: Codable {
    let version: Int
    var blocks: [RichPostBlock]
    var flags: [String]?      // pinned / featured / autoplay (group-admin toggles)
    var replyToId: String?    // public-post threading
    static let contentType = "application/vnd.loxation.richmedia+json"
}
```

But the editor-side `RichPostContent` (this package, `Sources/RichmediaEditor/Models/RichPostContent.swift`) has only `version`, `blocks`, `musicTrack`. The wire `contentType` is the same in both places.

Today `PublicPostComposerView.swift:1493-1500` does:

```swift
if let editorJSON = finalContent.toJSONString(),
   var loxContent = RichPostContent.fromJSON(editorJSON),
   (!postFlags.isEmpty || replyToId != nil) {
    if !postFlags.isEmpty { loxContent.flags = Array(postFlags) }
    if let rid = replyToId { loxContent.replyToId = rid }
    richMediaJSON = loxContent.toJSONString() ?? editorJSON
} else {
    richMediaJSON = finalContent.toJSONString() ?? messageText
}
```

The else-branch sends the editor's JSON verbatim — animation metadata survives.

The if-branch round-trips through `loxation/Models/RichPostContent.swift`, which **doesn't declare** `musicTrack` / `textLayers` / `lottieOverlay` / `mediaTransform`. `JSONDecoder` silently drops the unknown keys; `JSONEncoder` doesn't emit them again. So an animated post that's been pinned, featured, or marked as a reply loses its animations on the way to the server.

The same pattern repeats inside the new background queue at `PublicPostQueueService.swift:323-365` (substituting block media IDs + injecting `flags`/`replyToId`), and any future queue or edit path that needs to attach those two fields. Each such site has to choose between preserving animations OR preserving flags — never both.

If the editor's `RichPostContent` carried `flags` and `replyToId` as opt-in passthrough fields, the consuming app could decode → mutate → encode against **one** model with no loss. This is exactly what `musicTrack` already does — the editor doesn't render it for purposes the consuming app cares about (UI plays it via `GalleryPlayerView`, but the editor side treats it as data); it just preserves the field.

## What the consuming app uses these for

- **`flags`** — currently three string values, mutually independent (`loxation-sw/loxation/Views/PublicPostComposerView.swift:904-929`):
  - `"pinned"` — group admins can pin a public post to the top of the group feed.
  - `"featured"` — admin-curated highlight; renders a star icon in the bubble header.
  - `"autoplay"` — for galleries with `textLayers` / video, signals the player should autoplay.
  Open-ended list; the editor does **not** need to know the value set. Just round-trip the array.

- **`replyToId`** — if set, the post is a reply to another public post by id (UUID string). Used by the feed to render a "Replying to …" header. The editor does **not** need to render this; it's metadata for the feed.

## JSON shape (canonical spec update)

The spec at `../loxation-sw/docs/guide_to_richmedia_posts.md` currently documents the root object as:

```json
{
  "version": 1,
  "blocks": [ ... ]
}
```

Proposed:

```json
{
  "version": 1,
  "blocks": [ ... ],
  "musicTrack": { ... } | null,
  "flags": ["pinned", "autoplay"] | null,
  "replyToId": "550e8400-…" | null
}
```

with `flags` and `replyToId` documented as optional and absent-when-empty. Spec update should land in lockstep with this package change (a PR against `loxation-sw` will accompany).

## Backwards compatibility

- Old payloads (no `flags`, no `replyToId`) decode unchanged — both default to `nil`.
- Editor UI ignores the new fields entirely; existing previews and exports keep working.
- `toJSONString()` already uses `JSONEncoder` with `outputFormatting = [.sortedKeys]` — by default, `nil` Optional values are encoded as absent (no `"flags": null` in the JSON). Existing byte-stable JSON for posts that don't use the new fields stays byte-stable.
- No version bump needed; this is additive within `version: 1`.

## Out of scope (please don't bundle these)

- **No UI** for either field in the editor — they're metadata, surfaced/edited by the consuming app's composer.
- No enum / validation for `flags` values — keep it `[String]?`. The set of recognized flags lives in the consuming app and changes faster than the editor releases.
- No `replyToId` UI affordance — the editor doesn't display threading.

## Validation checklist

For the loxation-sw consumer side, the change is good once:

- [ ] `RichPostContent(blocks: [...], flags: ["pinned"])` round-trips via `toJSONString()` / `fromJSONString()` with `flags == ["pinned"]` preserved.
- [ ] `RichPostContent(blocks: [...], replyToId: "abc")` round-trips similarly.
- [ ] A payload **without** the new keys decodes with `flags == nil && replyToId == nil`.
- [ ] Encoding a `RichPostContent` with `flags == nil` does **not** emit `"flags": null` in the JSON (Swift `JSONEncoder` default Optional encoding).
- [ ] An animated post with `textLayers` + `musicTrack` + `flags = ["pinned"]` round-trips with **all four** intact — this is the regression we're solving.

## Cross-platform coordination

The Android library at `../richmedia-editor-android` has the same gap. A parallel proposal lives at `../richmedia-editor-android/RICHMEDIA_PARITY_REQUEST.md`. Both libraries need to ship the additive model change before either app can rely on it; otherwise iOS-encoded richmedia bodies with flags/replyToId would round-trip lossily through Android (and vice versa). Ideal order:

1. Spec update (`loxation-sw/docs/guide_to_richmedia_posts.md`) — adds the two optional keys.
2. Both editor libraries (this Swift Package + the Android lib) ship the additive model change.
3. loxation-sw + loxation-android stop forking the wire model for flag/replyToId injection — they decode against the editor's `RichPostContent` directly, mutate `flags` / `replyToId`, encode, send.

If sequencing is a problem, please flag — we can ship one side first as long as the consuming app keeps its raw-JSON splicing fallback for the cross-platform read path.

## Contact

This request is owned by the loxation-android team in coordination with loxation-sw. File issues / questions against [loxation-android #TBD] or reach out in #public-posts.
