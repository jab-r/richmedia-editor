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

## RichPostBlock

Each block is a JSON object with a unique `id`. The block type is inferred from which media key is present. Exactly one of `text`, `image`, or `video` will be non-null (if none are present, the block is treated as a text-type block).

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `id` | UUID string | yes | auto-generated | Unique identifier for the block |
| `text` | string | no | null | Text content (for text-only blocks) |
| `image` | string | no | null | Media ID / photoId (for image blocks) |
| `video` | string | no | null | Media ID (for video blocks) |
| `url` | string | no | null | CDN URL for display (required for image/video blocks) |
| `caption` | string | no | null | Caption text |
| `textLayers` | array | no | null | Array of `TextLayer` objects (max 10 per block) |
| `mediaTransform` | MediaTransform | no | null | Zoom/pan framing of media within the canvas |
| `lottieOverlay` | LottieAnimation | no | null | Lottie animation rendered on top of media |
| `animationVersion` | int | no | null | Reserved for future animation engine changes |

### Block Type Inference

The block type is determined by which key is present:

| Condition | Type | Rendering |
|-----------|------|-----------|
| `video` is non-null | Video block | Video player with media controls |
| `image` is non-null | Image block | Image display |
| Neither | Text block | Styled text content |

### Text Block

A standalone text block (no media background). Uses `text` for content and optional `style` for formatting.

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "text": "Hello world"
}
```

With optional styling:

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440001",
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
| `style` | TextBlockStyle | no | Styling (see TextBlockStyle section) |

### Image Block

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440002",
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
  "id": "550e8400-e29b-41d4-a716-446655440003",
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

For simple media posts: **media first, caption second** (caption style). For gallery/carousel posts, blocks are rendered as a horizontally swipeable sequence (see Gallery Rendering).

---

## Animated Posts (Text Overlays)

Image and video blocks can include **text layers** — positioned, styled, animated text overlays rendered on top of the media in a 9:16 canvas. This enables Instagram Stories / TikTok-style compositions.

When `textLayers` is present on a media block, the block is rendered as an **animated post** rather than a simple media display.

### Image/Video Block with Text Layers

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440004",
  "image": "cf-abc123",
  "url": "https://cdn.example.com/photo.jpg",
  "textLayers": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440010",
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

---

## TextLayer

A positioned, styled, optionally animated text overlay. Each text layer is rendered on top of the media background within the 9:16 canvas.

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440010",
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
| `id` | UUID string | yes | auto-generated | Unique identifier |
| `text` | string | yes | — | Text content to display |
| `position` | LayerPosition | yes | `{x:0.5, y:0.5, rotation:0, scale:1.0}` | Position within canvas |
| `style` | TextLayerStyle | yes | see defaults below | Text styling |
| `animation` | TextAnimation | no | null | Animation preset and timing |
| `path` | AnimationPath | no | null | Motion path (for `motionPath`/`curvePath` presets) |
| `visible` | bool | no | `true` | Whether layer is rendered |
| `zIndex` | int | no | `0` | Stacking order (higher = on top) |
| `lottieAnimation` | LottieAnimation | no | null | Per-layer Lottie animation (alternative to presets) |

---

## LayerPosition

All position values are **normalized to the canvas dimensions** (0.0 to 1.0) for device independence. The canvas uses a **9:16 aspect ratio**.

```json
{ "x": 0.5, "y": 0.5, "rotation": 0, "scale": 1.0 }
```

| Property | Type | Default | Range | Description |
|----------|------|---------|-------|-------------|
| `x` | float | `0.5` | 0.0–1.0 | Horizontal position (0.0 = left edge, 1.0 = right edge) |
| `y` | float | `0.5` | 0.0–1.0 | Vertical position (0.0 = top edge, 1.0 = bottom edge) |
| `rotation` | float | `0` | 0–360 | Rotation in degrees (clockwise, wraps via modulo 360) |
| `scale` | float | `1.0` | 0.5–3.0 | Scale factor (1.0 = default size) |

**Coordinate system:** `(0, 0)` is top-left, `(1, 1)` is bottom-right. The position specifies the **center point** of the text element. So `(0.5, 0.5)` places the text at the exact center of the canvas.

**Transform order:** Position first, then scale, then rotation (all relative to the element's center).

---

## TextLayerStyle

Full text styling for overlays.

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
| `size` | float | `32` | Font size in points |
| `color` | string | `"#FFFFFF"` | Text color as hex `#RRGGBB` |
| `backgroundColor` | string | `null` | Background highlight color behind text as hex |
| `bold` | bool | `false` | Bold weight |
| `italic` | bool | `false` | Italic style |
| `underline` | bool | `false` | Underline decoration |
| `strikethrough` | bool | `false` | Strikethrough decoration |
| `align` | string | `"center"` | Text alignment: `"left"`, `"center"`, `"right"` |
| `shadow` | TextShadow | `null` | Drop shadow effect |
| `outline` | TextOutline | `null` | Text outline/stroke effect |

### TextShadow

```json
{ "color": "#000000", "opacity": 0.5, "radius": 4, "offset": { "width": 0, "height": 2 } }
```

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `color` | string | `"#000000"` | Shadow color as hex |
| `opacity` | float | `0.5` | Shadow opacity (0.0–1.0) |
| `radius` | float | `4` | Blur radius in points |
| `offset` | object | `{width:0, height:2}` | Shadow offset `{width, height}` in points |

### TextOutline

```json
{ "color": "#000000", "width": 2 }
```

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `color` | string | `"#000000"` | Outline color as hex |
| `width` | float | `2` | Outline width in points |

---

## TextAnimation

Controls how a text layer animates. If null, the text is static (no animation).

```json
{ "preset": "fadeSlideUp", "delay": 0, "duration": 0.8, "loop": false, "loopDelay": 0 }
```

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `preset` | string | — (required) | Animation preset name (see table below) |
| `delay` | float | `0` | Delay before animation starts (seconds) |
| `duration` | float | `0.8` | Animation duration (seconds) |
| `loop` | bool | `false` | Whether animation repeats continuously |
| `loopDelay` | float | `0` | Delay between loop cycles (seconds). Only relevant when `loop` is `true` |

### Animation Presets

There are 19 presets organized into four categories.

#### Entrance (play once, bring element in)

| Preset | Description | Effect |
|--------|-------------|--------|
| `fadeIn` | Opacity 0 → 1 | Simple fade appearance |
| `fadeSlideUp` | Fade in + slide up | Opacity 0 → 1 with Y translation from below |
| `fadeSlideDown` | Fade in + slide down | Opacity 0 → 1 with Y translation from above |
| `fadeSlideLeft` | Fade in + slide left | Opacity 0 → 1 with X translation from right |
| `fadeSlideRight` | Fade in + slide right | Opacity 0 → 1 with X translation from left |
| `zoomIn` | Scale up with fade | Scale 0.5 → 1.0 with opacity 0 → 1 |
| `bounceIn` | Spring scale | Scale 0 → 1.0 with spring easing |
| `popIn` | Spring scale with fade | Scale 0.3 → 1.0 with spring easing and opacity 0 → 1 |

#### Exit (play once, take element out)

| Preset | Description | Effect |
|--------|-------------|--------|
| `fadeOut` | Opacity 1 → 0 | Simple fade disappearance |
| `slideOutUp` | Slide up + fade out | Y translation upward with opacity 1 → 0 |
| `slideOutDown` | Slide down + fade out | Y translation downward with opacity 1 → 0 |
| `zoomOut` | Scale down with fade | Scale 1.0 → 0.5 with opacity 1 → 0 |

#### Loop (repeating continuous effects)

These presets should have `loop: true` set. They oscillate continuously.

| Preset | Description | Effect |
|--------|-------------|--------|
| `pulse` | Scale oscillation | Scale oscillates 1.0 ↔ 1.1 |
| `bounce` | Vertical bounce | Y offset oscillates 0 ↔ -10pt |
| `float` | Gentle float | Y offset oscillates -8pt ↔ +8pt |
| `wiggle` | Rotation wiggle | Rotation oscillates -5° ↔ +5° |
| `rotate` | Continuous rotation | 360° clockwise rotation per cycle |

#### Path (requires `path` field on TextLayer)

These presets require a corresponding `AnimationPath` in the layer's `path` field.

| Preset | Description | Effect |
|--------|-------------|--------|
| `motionPath` | Follow drawn path | Move along user-drawn control points |
| `curvePath` | Follow curve path | Move along interpolated curve through control points |

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
| `type` | string | — (required) | Path type (see table below) |
| `points` | array | `[]` | Array of `{x, y}` control points (normalized 0.0–1.0) |
| `curveType` | string | `"quadratic"` | Curve interpolation method |

### Path Types

| Type | Description |
|------|-------------|
| `linear` | Straight line movement between points |
| `bezier` | Smooth curved path through control points |
| `circular` | Movement along a circular arc |
| `arc` | Movement along an elliptical arc |
| `wave` | Sinusoidal wave movement |
| `custom` | User-drawn freeform path |

### Curve Types

| Type | Description |
|------|-------------|
| `quadratic` | Quadratic Bezier interpolation (3 control points per segment) |
| `cubic` | Cubic Bezier interpolation (4 control points per segment) |

---

## MediaTransform

Controls how the background media (image/video) is framed within the 9:16 canvas. Allows the user to zoom in and pan to crop/position the media.

If null or absent, media is displayed with **scale-to-fill** at default position (centered, no zoom).

```json
{ "scale": 1.2, "offsetX": 15.5, "offsetY": -30.0 }
```

| Property | Type | Default | Range | Description |
|----------|------|---------|-------|-------------|
| `scale` | float | `1.0` | 1.0–5.0 | Zoom factor. 1.0 = fill frame, >1.0 = zoom in |
| `offsetX` | float | `0` | clamped | Horizontal offset in points from center |
| `offsetY` | float | `0` | clamped | Vertical offset in points from center |

**Offset clamping:** Offsets are constrained so that the scaled media always covers the entire canvas — no empty gaps at edges. The maximum allowed offset is `canvasSize * (scale - 1) / 2` in each axis. At `scale: 1.0`, no panning is possible (`offsetX` and `offsetY` must be 0).

### Rendering

Apply transforms in this order:

1. Display the media using **scale-to-fill** (the media fills the entire 9:16 canvas, cropping the shorter dimension)
2. Scale the media by `scale` factor (centered on the canvas)
3. Offset by `(offsetX, offsetY)` points
4. Clip to the 9:16 canvas bounds

---

## LottieAnimation

A Lottie animation overlay. Can appear at the block level (`lottieOverlay`, rendered on top of media but below text layers) or per text layer (`lottieAnimation`, attached to a specific layer).

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
| `jsonData` | string | — (required) | Complete Lottie animation JSON (stringified) |
| `name` | string | — (required) | Human-readable name |
| `duration` | float | — (required) | Animation duration in seconds |
| `frameRate` | float | `60` | Frame rate (fps) |
| `loops` | bool | `false` | Whether animation loops |

---

## TextBlockStyle (for text-only blocks)

Used on text blocks (blocks with the `text` key). Simpler than `TextLayerStyle` — no shadow/outline.

All properties are **optional**; omit to use defaults.

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `font` | string | System | Font family |
| `size` | int | 16 | Font size (10–48) |
| `color` | string | `"#000000"` | Hex color `#RRGGBB` |
| `backgroundColor` | string | null | Hex color for highlight |
| `bold` | bool | false | Bold text |
| `italic` | bool | false | Italic text |
| `underline` | bool | false | Underline |
| `strikethrough` | bool | false | Strikethrough |
| `align` | string | `"left"` | `"left"`, `"center"`, `"right"` |

---

## Allowed Fonts

Cross-platform safe fonts. Renderers should fall back to the system default if a font is unavailable.

| Font Name | Style | CSS Fallback |
|-----------|-------|--------------|
| `System` | Platform default sans-serif | `system-ui, -apple-system, sans-serif` |
| `Georgia` | Serif, elegant | `Georgia, serif` |
| `Times New Roman` | Serif, classic | `"Times New Roman", Times, serif` |
| `Helvetica` | Sans-serif, clean | `Helvetica, Arial, sans-serif` |
| `Arial` | Sans-serif, universal | `Arial, Helvetica, sans-serif` |
| `Courier` | Monospace | `"Courier New", Courier, monospace` |
| `Menlo` | Monospace, code | `Menlo, Consolas, monospace` |

---

## Constraints and Limits

These constraints are enforced by the editor and should be respected by all renderers:

| Constraint | Value | Description |
|------------|-------|-------------|
| Max text layers per block | 10 | Hard limit on `textLayers` array length |
| Canvas aspect ratio | 9:16 | All animated post rendering uses portrait Stories format |
| Layer position range | 0.0–1.0 | Both `x` and `y` are clamped to canvas bounds |
| Layer scale range | 0.5–3.0 | Text layer scale factor limits |
| Media scale range | 1.0–5.0 | MediaTransform zoom factor limits |
| Rotation range | 0–360 | Degrees, wraps via modulo 360 |
| Animation duration | > 0 | Must be a positive value in seconds |
| Animation delay | >= 0 | Non-negative value in seconds |

---

## Rendering Guide

### Simple blocks (no textLayers)

Iterate through `blocks` array in order and render each based on which key is present:

```kotlin
fun renderBlock(block: JsonObject): View {
    return when {
        block.has("video") -> renderVideoBlock(block)
        block.has("image") -> renderImageBlock(block)
        block.has("text")  -> renderTextBlock(block)
        else -> EmptyView()
    }
}
```

- **Image**: Load from `url`, display as thumbnail, tap to fullscreen
- **Video**: Show thumbnail with play button, tap to play (HLS preferred)
- **Text**: Apply `style` properties, default to system font size 16

### Animated posts (blocks with textLayers)

When a media block has `textLayers`, render as a **9:16 canvas**:

1. **Background media**: Render the image/video using `scale-to-fill`, applying `mediaTransform`:
   - Scale by `mediaTransform.scale` (centered)
   - Offset by `(offsetX, offsetY)` points
   - Clip to the 9:16 canvas bounds
2. **Lottie overlay**: If `lottieOverlay` is present, render on top of media but below text layers
3. **Text layers**: For each layer in `textLayers` where `visible` is `true`, sorted by `zIndex` (ascending):
   a. Render styled text using `style` properties
   b. Position center point at `(position.x * canvasWidth, position.y * canvasHeight)`
   c. Apply `position.scale` (centered on text)
   d. Apply `position.rotation` (clockwise, centered on text)
   e. Apply `animation` if present (see Animation Behavior below)
   f. If `lottieAnimation` is present on the layer, render it attached to the layer

### Gallery rendering (multi-block posts)

When a `RichPostContent` has multiple blocks, render as a **horizontally swipeable gallery/carousel**:

- Display one block at a time in a 9:16 canvas
- Show page indicator dots or a counter (e.g., "1 / 5")
- Horizontal swipe navigates between blocks
- Each block renders independently (its own `textLayers`, `mediaTransform`, `lottieOverlay`)
- Animations play per-block when the block becomes visible
- Auto-advance is optional (not specified in the format — up to the renderer)

### Animation behavior

**Entrance animations** play once when the block becomes visible:
- Apply the animation from its initial state to its final state over `duration` seconds
- Wait `delay` seconds before starting
- After completion, the element remains in its final state (fully visible)

**Exit animations** play once:
- Apply the animation from fully visible to hidden over `duration` seconds
- Wait `delay` seconds before starting
- After completion, the element remains in its final state (hidden/faded)

**Loop animations** repeat continuously:
- Oscillate between start and end states over `duration` seconds per cycle
- Wait `loopDelay` seconds between each cycle
- Continue indefinitely while the block is visible

**Path animations** move the element along a defined path:
- Requires a corresponding `AnimationPath` in the layer's `path` field
- The element moves through the control points over `duration` seconds
- The path coordinates are normalized (0.0–1.0) matching the canvas coordinate system

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

### CSS animation mappings

Map animation presets to CSS `@keyframes`. Apply with `animation-delay` matching the layer's `delay`, and `animation-duration` matching `duration`. For looping presets, use `animation-iteration-count: infinite`.

```css
/* Entrance */
@keyframes fadeIn {
  from { opacity: 0; }
  to { opacity: 1; }
}

@keyframes fadeSlideUp {
  from { opacity: 0; transform: translateY(50px); }
  to { opacity: 1; transform: translateY(0); }
}

@keyframes fadeSlideDown {
  from { opacity: 0; transform: translateY(-50px); }
  to { opacity: 1; transform: translateY(0); }
}

@keyframes fadeSlideLeft {
  from { opacity: 0; transform: translateX(50px); }
  to { opacity: 1; transform: translateX(0); }
}

@keyframes fadeSlideRight {
  from { opacity: 0; transform: translateX(-50px); }
  to { opacity: 1; transform: translateX(0); }
}

@keyframes zoomIn {
  from { opacity: 0; transform: scale(0.5); }
  to { opacity: 1; transform: scale(1.0); }
}

@keyframes bounceIn {
  0% { transform: scale(0); }
  60% { transform: scale(1.15); }
  80% { transform: scale(0.95); }
  100% { transform: scale(1.0); }
}

@keyframes popIn {
  0% { opacity: 0; transform: scale(0.3); }
  60% { opacity: 1; transform: scale(1.1); }
  100% { opacity: 1; transform: scale(1.0); }
}

/* Exit */
@keyframes fadeOut {
  from { opacity: 1; }
  to { opacity: 0; }
}

@keyframes slideOutUp {
  from { opacity: 1; transform: translateY(0); }
  to { opacity: 0; transform: translateY(-50px); }
}

@keyframes slideOutDown {
  from { opacity: 1; transform: translateY(0); }
  to { opacity: 0; transform: translateY(50px); }
}

@keyframes zoomOut {
  from { opacity: 1; transform: scale(1.0); }
  to { opacity: 0; transform: scale(0.5); }
}

/* Loop (use animation-iteration-count: infinite) */
@keyframes pulse {
  0%, 100% { transform: scale(1.0); }
  50% { transform: scale(1.1); }
}

@keyframes bounce {
  0%, 100% { transform: translateY(0); }
  50% { transform: translateY(-10px); }
}

@keyframes float {
  0%, 100% { transform: translateY(-8px); }
  50% { transform: translateY(8px); }
}

@keyframes wiggle {
  0%, 100% { transform: rotate(-5deg); }
  50% { transform: rotate(5deg); }
}

@keyframes rotate {
  from { transform: rotate(0deg); }
  to { transform: rotate(360deg); }
}
```

**Usage example:**
```css
.text-layer {
  animation-name: fadeSlideUp;
  animation-duration: 0.8s;
  animation-delay: 0.5s;
  animation-fill-mode: both;
  animation-timing-function: ease-out;
}

.text-layer-looping {
  animation-name: pulse;
  animation-duration: 1.0s;
  animation-iteration-count: infinite;
  animation-timing-function: ease-in-out;
}
```

---

## Complete Examples

### Simple photo with caption

```json
{
  "version": 1,
  "blocks": [
    {
      "id": "a1b2c3d4-0000-0000-0000-000000000001",
      "image": "cf-abc123",
      "url": "https://cdn.example.com/photo.jpg"
    },
    {
      "id": "a1b2c3d4-0000-0000-0000-000000000002",
      "text": "Beautiful sunset at the beach!"
    }
  ]
}
```

### Animated post with text overlays

```json
{
  "version": 1,
  "blocks": [
    {
      "id": "a1b2c3d4-0000-0000-0000-000000000001",
      "image": "cf-abc123",
      "url": "https://cdn.example.com/photo.jpg",
      "mediaTransform": { "scale": 1.3, "offsetX": 0, "offsetY": -20 },
      "textLayers": [
        {
          "id": "a1b2c3d4-0000-0000-0000-000000000010",
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
          "id": "a1b2c3d4-0000-0000-0000-000000000011",
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

A multi-block post renders as a swipeable carousel. Each block has its own media, text layers, and transforms.

```json
{
  "version": 1,
  "blocks": [
    {
      "id": "a1b2c3d4-0000-0000-0000-000000000001",
      "image": "cf-slide1",
      "url": "https://cdn.example.com/slide1.jpg",
      "textLayers": [
        {
          "id": "a1b2c3d4-0000-0000-0000-000000000010",
          "text": "Slide 1",
          "position": { "x": 0.5, "y": 0.5, "rotation": 0, "scale": 1.0 },
          "style": { "font": "System", "size": 32, "color": "#FFFFFF", "align": "center" },
          "visible": true,
          "zIndex": 0
        }
      ]
    },
    {
      "id": "a1b2c3d4-0000-0000-0000-000000000002",
      "image": "cf-slide2",
      "url": "https://cdn.example.com/slide2.jpg",
      "mediaTransform": { "scale": 1.5, "offsetX": 10, "offsetY": 0 },
      "textLayers": [
        {
          "id": "a1b2c3d4-0000-0000-0000-000000000020",
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
      "id": "a1b2c3d4-0000-0000-0000-000000000001",
      "video": "cf-xyz789",
      "url": "https://cdn.example.com/video.m3u8",
      "textLayers": [
        {
          "id": "a1b2c3d4-0000-0000-0000-000000000010",
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

### Animated post with motion path

```json
{
  "version": 1,
  "blocks": [
    {
      "id": "a1b2c3d4-0000-0000-0000-000000000001",
      "image": "cf-abc123",
      "url": "https://cdn.example.com/photo.jpg",
      "textLayers": [
        {
          "id": "a1b2c3d4-0000-0000-0000-000000000010",
          "text": "Follow the path",
          "position": { "x": 0.2, "y": 0.3, "rotation": 0, "scale": 1.0 },
          "style": { "font": "System", "size": 24, "color": "#FFFFFF" },
          "animation": { "preset": "motionPath", "delay": 0, "duration": 2.0, "loop": true, "loopDelay": 0.5 },
          "path": {
            "type": "custom",
            "points": [
              { "x": 0.2, "y": 0.3 },
              { "x": 0.5, "y": 0.1 },
              { "x": 0.8, "y": 0.4 },
              { "x": 0.5, "y": 0.7 }
            ],
            "curveType": "quadratic"
          },
          "visible": true,
          "zIndex": 0
        }
      ]
    }
  ]
}
```

### Animated post with Lottie overlay

```json
{
  "version": 1,
  "blocks": [
    {
      "id": "a1b2c3d4-0000-0000-0000-000000000001",
      "image": "cf-abc123",
      "url": "https://cdn.example.com/photo.jpg",
      "lottieOverlay": {
        "jsonData": "{\"v\":\"5.5.7\",\"fr\":60,...}",
        "name": "confetti",
        "duration": 3.0,
        "frameRate": 60,
        "loops": true
      },
      "textLayers": [
        {
          "id": "a1b2c3d4-0000-0000-0000-000000000010",
          "text": "Congratulations!",
          "position": { "x": 0.5, "y": 0.5, "rotation": 0, "scale": 1.5 },
          "style": { "font": "Helvetica", "size": 40, "color": "#FFD700", "bold": true, "align": "center" },
          "animation": { "preset": "popIn", "delay": 0.3, "duration": 0.6, "loop": false, "loopDelay": 0 },
          "visible": true,
          "zIndex": 0
        }
      ]
    }
  ]
}
```

---

## Rendering Stack Order

For animated post blocks, the visual stacking order (bottom to top) is:

1. **Background media** (image or video, with `mediaTransform` applied)
2. **Lottie overlay** (`lottieOverlay` on the block, if present)
3. **Text layers** (sorted ascending by `zIndex`, then by array order for equal `zIndex`)

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

### JSON encoding notes

- Use sorted keys for consistent output (the iOS encoder uses `JSONEncoder.OutputFormatting.sortedKeys`)
- Omitted optional fields (null values) should not be serialized — keep the JSON compact
- UUIDs are serialized as lowercase hyphenated strings (e.g., `"550e8400-e29b-41d4-a716-446655440000"`)

## Validation

A valid `RichPostContent` document must satisfy:

- `version` is `1`
- `blocks` is a non-empty array
- Each block has a unique `id`
- Image blocks have both `image` and `url` set
- Video blocks have both `video` and `url` set
- `textLayers` has at most 10 entries per block
- Each text layer has a unique `id` and non-empty `text`
- `LayerPosition.x` and `y` are within 0.0–1.0
- `LayerPosition.scale` is within 0.5–3.0
- `MediaTransform.scale` is within 1.0–5.0
- Color strings are valid `#RRGGBB` hex format
- `animation.preset` is one of the 19 defined preset strings
- Path-based animation presets (`motionPath`, `curvePath`) have a corresponding non-null `path`

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
