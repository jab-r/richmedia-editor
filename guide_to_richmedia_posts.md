# Guide to Rich Media Posts

This document is the **canonical specification** for the `richmedia` content type. All platforms (iOS, Android, web) must implement rendering according to this spec to ensure interoperability.

## Content Type

```
application/vnd.loxation.richmedia+json
```

When a post has this `contentType`, the `message` field contains JSON (not plain text).

## JSON Schema

### Root Object: `RichPostContent`

```json
{
  "version": 1,
  "blocks": [ ... ]
}
```

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `version` | int | yes | Schema version. Currently `1` |
| `blocks` | array | yes | Ordered list of `RichPostBlock` objects |

---

## Block Types

Each block is a JSON object. The block type is inferred from which key is present. Exactly one of `text`, `image`, or `video` will be non-null.

### Text Block

```json
{ "text": "Hello world" }
```

With optional styling:

```json
{
  "text": "Styled text",
  "style": {
    "bold": true,
    "color": "#FF6B35",
    "size": 18
  }
}
```

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `text` | string | yes | Text content |
| `style` | TextBlockStyle | no | Styling (see below) |

### Image Block

```json
{
  "image": "cf-abc123",
  "url": "https://cdn.example.com/image.jpg",
  "caption": "Optional caption"
}
```

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `image` | string | yes | Media ID (photoId) |
| `url` | string | yes | CDN URL for display |
| `caption` | string | no | Caption text |

### Video Block

```json
{
  "video": "cf-xyz789",
  "url": "https://cdn.example.com/video.m3u8",
  "caption": "Optional caption"
}
```

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `video` | string | yes | Media ID |
| `url` | string | yes | Playback URL (HLS preferred) |
| `caption` | string | no | Caption text |

### Block Order

For simple media posts: **media first, caption second** (caption style).

---

## Animated Posts (Text Overlays)

Image and video blocks can include **text layers** — positioned, styled, animated text overlays rendered on top of the media in a 9:16 canvas. This enables Instagram Stories / TikTok-style compositions.

When `textLayers` is present on a media block, the block is rendered as an **animated post** rather than a simple media display.

### Image/Video Block with Text Layers

```json
{
  "image": "cf-abc123",
  "url": "https://cdn.example.com/photo.jpg",
  "textLayers": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "text": "Hello World!",
      "position": { "x": 0.5, "y": 0.3, "rotation": 0, "scale": 1.0 },
      "style": { "font": "System", "size": 32, "color": "#FFFFFF", "bold": true },
      "animation": { "preset": "fadeIn", "duration": 0.8, "delay": 0, "loop": false, "loopDelay": 0 },
      "visible": true,
      "zIndex": 0
    }
  ],
  "mediaTransform": { "scale": 1.2, "offsetX": 0, "offsetY": -30 }
}
```

### Additional Block Properties (for animated posts)

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `textLayers` | array | no | null | Array of `TextLayer` objects (max 10) |
| `mediaTransform` | MediaTransform | no | null | Zoom/pan framing of the media within canvas |
| `lottieOverlay` | LottieAnimation | no | null | Lottie animation rendered on top of media |
| `animationVersion` | int | no | null | Reserved for future animation engine changes |

---

## TextLayer

A positioned, styled, optionally animated text overlay.

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "text": "Sample text",
  "position": { "x": 0.5, "y": 0.5, "rotation": 0, "scale": 1.0 },
  "style": { "font": "System", "size": 32, "color": "#FFFFFF" },
  "animation": null,
  "path": null,
  "visible": true,
  "zIndex": 0,
  "lottieAnimation": null
}
```

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `id` | UUID string | yes | auto | Unique identifier |
| `text` | string | yes | | Text content |
| `position` | LayerPosition | yes | centered | Position within canvas |
| `style` | TextLayerStyle | yes | defaults | Text styling |
| `animation` | TextAnimation | no | null | Animation preset and timing |
| `path` | AnimationPath | no | null | Motion path (for path-based animations) |
| `visible` | bool | no | true | Whether layer is rendered |
| `zIndex` | int | no | 0 | Stacking order (higher = on top) |
| `lottieAnimation` | LottieAnimation | no | null | Per-layer Lottie animation (alternative to presets) |

---

## LayerPosition

All position values are **normalized to the canvas dimensions** (0.0 to 1.0) for device independence. The canvas uses a **9:16 aspect ratio**.

```json
{ "x": 0.5, "y": 0.5, "rotation": 0, "scale": 1.0 }
```

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `x` | float | 0.5 | Horizontal position (0.0 = left edge, 1.0 = right edge) |
| `y` | float | 0.5 | Vertical position (0.0 = top edge, 1.0 = bottom edge) |
| `rotation` | float | 0 | Rotation in degrees (clockwise) |
| `scale` | float | 1.0 | Scale factor (1.0 = default size, 0.5–3.0 range) |

---

## TextLayerStyle

Full text styling for overlays. Extends the basic `TextBlockStyle` with shadow and outline support.

```json
{
  "font": "Helvetica",
  "size": 28,
  "color": "#FFFFFF",
  "backgroundColor": null,
  "bold": true,
  "italic": false,
  "underline": false,
  "strikethrough": false,
  "align": "center",
  "shadow": { "color": "#000000", "opacity": 0.5, "radius": 4, "offset": { "width": 0, "height": 2 } },
  "outline": { "color": "#000000", "width": 2 }
}
```

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `font` | string | `"System"` | Font family name (see Allowed Fonts) |
| `size` | float | 32 | Font size in points |
| `color` | string | `"#FFFFFF"` | Text color as hex `#RRGGBB` |
| `backgroundColor` | string | null | Background color behind text |
| `bold` | bool | false | Bold weight |
| `italic` | bool | false | Italic style |
| `underline` | bool | false | Underline decoration |
| `strikethrough` | bool | false | Strikethrough decoration |
| `align` | string | `"center"` | Text alignment: `"left"`, `"center"`, `"right"` |
| `shadow` | TextShadow | null | Drop shadow |
| `outline` | TextOutline | null | Text outline/stroke |

### TextShadow

```json
{ "color": "#000000", "opacity": 0.5, "radius": 4, "offset": { "width": 0, "height": 2 } }
```

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `color` | string | `"#000000"` | Shadow color as hex |
| `opacity` | float | 0.5 | Shadow opacity (0.0–1.0) |
| `radius` | float | 4 | Blur radius in points |
| `offset` | object | `{width:0, height:2}` | Shadow offset `{width, height}` in points |

### TextOutline

```json
{ "color": "#000000", "width": 2 }
```

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `color` | string | `"#000000"` | Outline color as hex |
| `width` | float | 2 | Outline width in points |

---

## TextAnimation

Controls how a text layer animates. If null, the text is static.

```json
{ "preset": "fadeSlideUp", "delay": 0, "duration": 0.8, "loop": false, "loopDelay": 0 }
```

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `preset` | string | | Animation preset name (see below) |
| `delay` | float | 0 | Delay before animation starts (seconds) |
| `duration` | float | 0.8 | Animation duration (seconds) |
| `loop` | bool | false | Whether animation repeats |
| `loopDelay` | float | 0 | Delay between loop cycles (seconds) |

### Animation Presets

#### Entrance (play once, bring element in)

| Preset | Description |
|--------|-------------|
| `fadeIn` | Opacity 0 → 1 |
| `fadeSlideUp` | Fade in + slide up from below |
| `fadeSlideDown` | Fade in + slide down from above |
| `fadeSlideLeft` | Fade in + slide in from right |
| `fadeSlideRight` | Fade in + slide in from left |
| `zoomIn` | Scale 0.5 → 1.0 with fade |
| `bounceIn` | Scale 0 → 1.0 with spring |
| `popIn` | Scale 0.3 → 1.0 with spring and fade |

#### Exit (play once, take element out)

| Preset | Description |
|--------|-------------|
| `fadeOut` | Opacity 1 → 0 |
| `slideOutUp` | Slide up + fade out |
| `slideOutDown` | Slide down + fade out |
| `zoomOut` | Scale 1.0 → 0.5 with fade |

#### Loop (repeating continuous effects)

| Preset | Description |
|--------|-------------|
| `pulse` | Scale oscillates 1.0 ↔ 1.1 |
| `bounce` | Vertical offset oscillates 0 ↔ -10pt |
| `float` | Vertical offset oscillates -8pt ↔ +8pt |
| `wiggle` | Rotation oscillates -5° ↔ +5° |
| `rotate` | Continuous 360° rotation |

#### Path (requires `path` field on TextLayer)

| Preset | Description |
|--------|-------------|
| `motionPath` | Move along a user-drawn path |
| `curvePath` | Move along a curve path |

---

## AnimationPath

Defines a motion path for path-based animations. Only used when `animation.preset` is `motionPath` or `curvePath`.

```json
{
  "type": "custom",
  "points": [ { "x": 0.1, "y": 0.2 }, { "x": 0.5, "y": 0.8 }, { "x": 0.9, "y": 0.3 } ],
  "curveType": "quadratic"
}
```

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `type` | string | | Path type (see below) |
| `points` | array | `[]` | Array of `{x, y}` control points (normalized 0.0–1.0) |
| `curveType` | string | `"quadratic"` | Interpolation: `"quadratic"` or `"cubic"` |

### Path Types

| Type | Description |
|------|-------------|
| `linear` | Straight line movement |
| `bezier` | Curved path movement |
| `circular` | Movement along a circle |
| `arc` | Movement along an arc |
| `wave` | Movement along a wave |
| `custom` | User-drawn freeform path |

---

## MediaTransform

Controls how the background media (image/video) is framed within the 9:16 canvas. Allows the user to zoom in and pan to crop/position the media.

If null or absent, media is displayed with **scale-to-fill** at default position.

```json
{ "scale": 1.2, "offsetX": 15.5, "offsetY": -30.0 }
```

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `scale` | float | 1.0 | Zoom factor. 1.0 = fill frame. Values > 1.0 zoom in |
| `offsetX` | float | 0 | Horizontal offset in points from center |
| `offsetY` | float | 0 | Vertical offset in points from center |

### Rendering

Apply in this order:
1. Scale the media by `scale` factor (centered)
2. Offset by `(offsetX, offsetY)` points
3. Clip to the 9:16 canvas bounds

---

## LottieAnimation

A Lottie animation overlay. Can appear at the block level (`lottieOverlay`) or per text layer (`lottieAnimation`).

```json
{
  "jsonData": "{...lottie json...}",
  "name": "confetti",
  "duration": 3.0,
  "frameRate": 60,
  "loops": false
}
```

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `jsonData` | string | | Complete Lottie animation JSON (stringified) |
| `name` | string | | Human-readable name |
| `duration` | float | | Animation duration in seconds |
| `frameRate` | float | 60 | Frame rate (fps) |
| `loops` | bool | false | Whether animation loops |

---

## TextBlockStyle (for text-only blocks)

Used on text blocks (blocks with the `text` key). Simpler than `TextLayerStyle` — no shadow/outline.

All properties are **optional**; omit to use defaults.

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `font` | string | System | Font family |
| `size` | int | 16 | Font size (10–48) |
| `color` | string | `"#000000"` | Hex color `#RRGGBB` |
| `backgroundColor` | string | null | Hex color |
| `bold` | bool | false | Bold text |
| `italic` | bool | false | Italic text |
| `underline` | bool | false | Underline |
| `strikethrough` | bool | false | Strikethrough |
| `align` | string | `"left"` | `"left"`, `"center"`, `"right"` |

---

## Allowed Fonts

Cross-platform safe fonts. Renderers should fall back to the system default if a font is unavailable.

| Font Name | Style |
|-----------|-------|
| `System` | Platform default sans-serif |
| `Georgia` | Serif, elegant |
| `Times New Roman` | Serif, classic |
| `Helvetica` | Sans-serif, clean |
| `Arial` | Sans-serif, universal |
| `Courier` | Monospace |
| `Menlo` | Monospace, code |

---

## Rendering Guide

### Simple blocks (no textLayers)

Iterate through `blocks` array in order and render each based on which key is present:

```kotlin
fun renderBlock(block: JsonObject): View {
    return when {
        block.has("text") -> renderTextBlock(block)
        block.has("image") -> renderImageBlock(block)
        block.has("video") -> renderVideoBlock(block)
        else -> EmptyView()
    }
}
```

- **Image**: Load from `url`, display as thumbnail, tap to fullscreen
- **Video**: Show thumbnail with play button, tap to play
- **Text**: Apply `style` properties, default to system font size 16

### Animated posts (blocks with textLayers)

When a media block has `textLayers`, render as a **9:16 canvas**:

1. **Background media**: Render the image/video, applying `mediaTransform` (scale, then offset, then clip)
2. **Lottie overlay**: If `lottieOverlay` is present, render on top of media
3. **Text layers**: For each layer in `textLayers` where `visible` is true:
   a. Render styled text using `style` properties
   b. Position at `(position.x * canvasWidth, position.y * canvasHeight)`
   c. Apply `position.scale` and `position.rotation`
   d. Apply `animation` if present (entrance/exit/loop/path)
   e. Stack in `zIndex` order

### HTML rendering

For server-side HTML export of animated posts, convert text layers to absolutely positioned elements within a 9:16 container:

```html
<div class="animated-post" style="position:relative; aspect-ratio:9/16; overflow:hidden;">
  <!-- Background media with transform -->
  <img src="..." style="
    position:absolute; width:100%; height:100%; object-fit:cover;
    transform: scale(1.2) translate(15.5px, -30px);
  " />

  <!-- Text layer -->
  <div style="
    position:absolute;
    left:50%; top:30%;
    transform: translate(-50%,-50%) rotate(0deg) scale(1.0);
    font-family: Helvetica, sans-serif;
    font-size: 28px;
    color: #FFFFFF;
    font-weight: bold;
    text-shadow: 0 2px 4px rgba(0,0,0,0.5);
  ">Hello World!</div>
</div>
```

For CSS animations, map presets to `@keyframes`:

```css
/* fadeSlideUp */
@keyframes fadeSlideUp {
  from { opacity: 0; transform: translateY(50px); }
  to { opacity: 1; transform: translateY(0); }
}

/* pulse (looping) */
@keyframes pulse {
  0%, 100% { transform: scale(1.0); }
  50% { transform: scale(1.1); }
}
```

---

## Complete Examples

### Simple photo with caption

```json
{
  "version": 1,
  "blocks": [
    { "image": "cf-abc123", "url": "https://cdn.example.com/photo.jpg" },
    { "text": "Beautiful sunset at the beach!" }
  ]
}
```

### Animated post with text overlays

```json
{
  "version": 1,
  "blocks": [
    {
      "image": "cf-abc123",
      "url": "https://cdn.example.com/photo.jpg",
      "mediaTransform": { "scale": 1.3, "offsetX": 0, "offsetY": -20 },
      "textLayers": [
        {
          "id": "a1b2c3d4-0000-0000-0000-000000000001",
          "text": "Summer Vibes",
          "position": { "x": 0.5, "y": 0.25, "rotation": -5, "scale": 1.2 },
          "style": {
            "font": "Helvetica",
            "size": 36,
            "color": "#FFFFFF",
            "bold": true,
            "italic": false,
            "underline": false,
            "strikethrough": false,
            "align": "center",
            "shadow": { "color": "#000000", "opacity": 0.6, "radius": 6, "offset": { "width": 0, "height": 3 } }
          },
          "animation": { "preset": "fadeSlideUp", "delay": 0, "duration": 0.8, "loop": false, "loopDelay": 0 },
          "visible": true,
          "zIndex": 1
        },
        {
          "id": "a1b2c3d4-0000-0000-0000-000000000002",
          "text": "Best day ever",
          "position": { "x": 0.5, "y": 0.7, "rotation": 0, "scale": 1.0 },
          "style": {
            "font": "Georgia",
            "size": 24,
            "color": "#FFD166",
            "bold": false,
            "italic": true,
            "underline": false,
            "strikethrough": false,
            "align": "center"
          },
          "animation": { "preset": "fadeIn", "delay": 0.5, "duration": 1.0, "loop": false, "loopDelay": 0 },
          "visible": true,
          "zIndex": 0
        }
      ]
    }
  ]
}
```

### Multi-slide animated post (gallery)

```json
{
  "version": 1,
  "blocks": [
    {
      "image": "cf-slide1",
      "url": "https://cdn.example.com/slide1.jpg",
      "textLayers": [
        {
          "id": "slide1-text",
          "text": "Slide 1",
          "position": { "x": 0.5, "y": 0.5, "rotation": 0, "scale": 1.0 },
          "style": { "font": "System", "size": 32, "color": "#FFFFFF", "align": "center" },
          "visible": true,
          "zIndex": 0
        }
      ]
    },
    {
      "image": "cf-slide2",
      "url": "https://cdn.example.com/slide2.jpg",
      "mediaTransform": { "scale": 1.5, "offsetX": 10, "offsetY": 0 },
      "textLayers": [
        {
          "id": "slide2-text",
          "text": "Slide 2",
          "position": { "x": 0.5, "y": 0.4, "rotation": 0, "scale": 1.0 },
          "style": { "font": "System", "size": 32, "color": "#FFFFFF", "align": "center" },
          "animation": { "preset": "bounceIn", "delay": 0, "duration": 0.8, "loop": false, "loopDelay": 0 },
          "visible": true,
          "zIndex": 0
        }
      ]
    }
  ]
}
```

### Video with looping text animation

```json
{
  "version": 1,
  "blocks": [
    {
      "video": "cf-xyz789",
      "url": "https://cdn.example.com/video.m3u8",
      "textLayers": [
        {
          "id": "video-text",
          "text": "LIVE",
          "position": { "x": 0.9, "y": 0.1, "rotation": 0, "scale": 0.8 },
          "style": {
            "font": "System",
            "size": 20,
            "color": "#FF0000",
            "bold": true,
            "align": "center",
            "outline": { "color": "#FFFFFF", "width": 1 }
          },
          "animation": { "preset": "pulse", "delay": 0, "duration": 1.0, "loop": true, "loopDelay": 0.5 },
          "visible": true,
          "zIndex": 0
        }
      ]
    }
  ]
}
```

---

## Creating Posts

When uploading media posts to the server:

1. Upload media via `/v1/posts/media/upload-url` flow (unchanged)
2. Build the richmedia JSON with blocks (media first, caption second)
3. POST to `/v1/post/create` with:
   - `message`: JSON string
   - `contentType`: `application/vnd.loxation.richmedia+json`
   - `mediaId`: the uploaded media ID

```json
{
  "message": "{\"version\":1,\"blocks\":[...]}",
  "messageId": "client-uuid",
  "contentType": "application/vnd.loxation.richmedia+json",
  "mediaId": "cf-abc123",
  "username": "myuser",
  "location": { "latitude": 40.7, "longitude": -74.0, "accuracyM": 250 }
}
```

## Backward Compatibility

- Posts with `contentType: text/plain` continue to work as before
- Unknown JSON properties must be **preserved** (do not strip on decode/re-encode) to allow older clients to round-trip documents without data loss
- If a client receives `richmedia+json` but can't parse animated post fields, it should fall back to rendering the media without text overlays
- If a client can't parse the JSON at all, show fallback: "Rich post - update app to view"

## Local Persistence

Store the full JSON in the `content` field. On rehydration:
1. Check `contentType`
2. Parse JSON to extract blocks
3. Render blocks in order
4. All state (text layers, positions, animations, media transform) is fully encoded in the JSON — no external state needed to restore a document
