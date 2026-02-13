# Animated Social Media Posts - Architecture

## Overview

This Swift Package provides an Instagram/TikTok-style animated post editor for iOS. It enables users to create professional-quality animated posts with text overlays on photos and videos, with support for entrance/exit animations, motion along paths, curved text, and more.

## Integration with Loxation

This is a standalone Swift Package that Loxation imports. The package provides:
- Clean public API via `AnimatedPostEditorView`
- Self-contained UI components
- JSON output in `RichPostContent` format
- No direct dependencies on Loxation internals

Loxation is responsible for:
- Media upload infrastructure (`PostMediaService`)
- JSON storage and API submission
- Post rendering in feed
- User authentication and profiles

## Architecture Decision: Hybrid Approach

### Phase 1: Custom JSON Format (Simple Overlays)
**For MVP**: Custom JSON schema optimized for text overlay presets
- Simpler to implement preset gallery
- Tailored to our specific needs
- Full control over features

### Phase 2: Lottie Import (Complex Animations)
**For power users**: Support importing Lottie JSON from After Effects
- Professional-grade animations
- Leverage existing ecosystem
- Reuse renderers (lottie-ios, lottie-web)

### Phase 3: Lottie Export (Future)
**For advanced users**: Export custom overlays as Lottie format
- Cross-platform compatibility
- External tool integration

---

## Data Model

### Extended RichPostBlock Schema

The package extends the existing `RichPostBlock` model from Loxation with animation capabilities:

```swift
struct RichPostBlock: Codable, Identifiable {
    let id: UUID

    // Media (existing)
    var image: String?
    var video: String?
    var url: String?
    var caption: String?

    // Text overlay layers (NEW)
    var textLayers: [TextLayer]?

    // Animation metadata (NEW)
    var animationVersion: Int?  // For versioning
}

struct TextLayer: Codable, Identifiable {
    let id: UUID
    var text: String
    var position: LayerPosition
    var style: TextLayerStyle
    var animation: TextAnimation?
    var path: AnimationPath?
    var visible: Bool = true
    var zIndex: Int = 0  // Layer ordering
}

struct LayerPosition: Codable {
    var x: CGFloat  // 0.0 to 1.0 (percentage of canvas width)
    var y: CGFloat  // 0.0 to 1.0 (percentage of canvas height)
    var rotation: CGFloat = 0  // Degrees
    var scale: CGFloat = 1.0
}

struct TextLayerStyle: Codable {
    var font: String = "System"
    var size: CGFloat = 32
    var color: String = "#FFFFFF"
    var backgroundColor: String? = nil
    var bold: Bool = false
    var italic: Bool = false
    var underline: Bool = false
    var strikethrough: Bool = false
    var align: TextAlignment = .center
    var shadow: TextShadow? = nil
    var outline: TextOutline? = nil
}

struct TextShadow: Codable {
    var color: String = "#000000"
    var opacity: CGFloat = 0.5
    var radius: CGFloat = 4
    var offset: CGSize = CGSize(width: 0, height: 2)
}

struct TextOutline: Codable {
    var color: String = "#000000"
    var width: CGFloat = 2
}

struct TextAnimation: Codable {
    var preset: AnimationPreset
    var delay: TimeInterval = 0  // Seconds from start
    var duration: TimeInterval = 0.8
    var loop: Bool = false
    var loopDelay: TimeInterval = 0
}

enum AnimationPreset: String, Codable {
    // Entrance effects
    case fadeIn
    case fadeSlideUp
    case fadeSlideDown
    case fadeSlideLeft
    case fadeSlideRight
    case zoomIn
    case bounceIn
    case popIn

    // Exit effects
    case fadeOut
    case slideOutUp
    case slideOutDown
    case zoomOut

    // Looping effects
    case pulse
    case bounce
    case float
    case wiggle
    case rotate

    // Path-based (requires AnimationPath)
    case motionPath
    case curvePath
}

struct AnimationPath: Codable {
    var type: PathType
    var points: [CGPoint]  // Control points for Bezier
    var curveType: CurveType = .quadratic
}

enum PathType: String, Codable {
    case linear      // Straight line movement
    case bezier      // Curved path movement
    case circular    // Text along circle
    case arc         // Text along arc
    case wave        // Text along wave
    case custom      // User-drawn path
}

enum CurveType: String, Codable {
    case quadratic   // 3 control points
    case cubic       // 4 control points
}
```

### JSON Example

```json
{
  "version": 1,
  "blocks": [
    {
      "image": "photo123",
      "url": "https://cdn.loxation.app/photo123.jpg",
      "textLayers": [
        {
          "id": "layer1",
          "text": "Hello World!",
          "position": {"x": 0.5, "y": 0.3, "rotation": 0, "scale": 1.0},
          "style": {
            "font": "Helvetica",
            "size": 48,
            "color": "#FFFFFF",
            "bold": true,
            "shadow": {"color": "#000000", "opacity": 0.6, "radius": 4}
          },
          "animation": {
            "preset": "fadeSlideUp",
            "delay": 0,
            "duration": 0.8,
            "loop": false
          }
        },
        {
          "id": "layer2",
          "text": "#Loxation",
          "position": {"x": 0.5, "y": 0.7, "rotation": -5, "scale": 0.8},
          "style": {
            "font": "Georgia",
            "size": 32,
            "color": "#FF6B35",
            "italic": true
          },
          "animation": {
            "preset": "pulse",
            "delay": 1.0,
            "duration": 1.0,
            "loop": true,
            "loopDelay": 0.5
          }
        }
      ]
    }
  ]
}
```

---

## Component Architecture

### Package Structure

```
RichmediaEditor/
├── Package.swift
├── Sources/
│   └── RichmediaEditor/
│       ├── Views/
│       │   ├── AnimatedPostEditorView.swift      (Main container - PUBLIC API)
│       │   ├── MediaCanvasView.swift             (Image/video background)
│       │   ├── TextLayerView.swift               (Draggable text overlay)
│       │   ├── TextLayerEditorSheet.swift        (Edit text + style)
│       │   ├── AnimationPresetPicker.swift       (Visual gallery)
│       │   ├── PathDrawingView.swift             (Draw motion paths)
│       │   └── AnimatedPostPlayerView.swift      (Playback + render)
│       ├── Models/
│       │   ├── TextLayer.swift
│       │   ├── LayerPosition.swift
│       │   ├── TextLayerStyle.swift
│       │   ├── TextAnimation.swift
│       │   ├── AnimationPath.swift
│       │   └── AnimationPreset.swift
│       ├── Services/
│       │   ├── AnimationRenderer.swift           (SwiftUI animation logic)
│       │   ├── VideoCompositor.swift             (AVFoundation compositing)
│       │   └── HTMLAnimationExporter.swift       (JSON → HTML/CSS/JS)
│       └── ViewModels/
│           └── AnimatedPostEditorViewModel.swift (State management)
├── Tests/
└── README.md
```

### Public API

The package exposes a single public view:

```swift
public struct AnimatedPostEditorView: View {
    let initialMedia: MediaInput?
    let onComplete: (RichPostContent) -> Void
    let onCancel: () -> Void

    public init(
        initialMedia: MediaInput? = nil,
        onComplete: @escaping (RichPostContent) -> Void,
        onCancel: @escaping () -> Void
    )
}

public enum MediaInput {
    case image(UIImage)
    case video(URL)
}
```

### Loxation Integration

Loxation integrates the editor with ~100 lines of code:

```swift
// In Loxation app
import RichmediaEditor

struct CreateAnimatedPostView: View {
    @StateObject private var chatViewModel: ChatViewModel
    @State private var showEditor = false
    @State private var selectedMedia: MediaInput?

    var body: some View {
        Button("Create Animated Post") {
            showEditor = true
        }
        .sheet(isPresented: $showEditor) {
            AnimatedPostEditorView(
                initialMedia: selectedMedia,
                onComplete: { richContent in
                    Task {
                        // Upload media via Loxation's PostMediaService
                        let uploadResult = await uploadMedia(richContent)

                        // Submit via existing API
                        chatViewModel.addPublicPost(
                            "",
                            messageId: UUID().uuidString,
                            richContent: richContent
                        )
                    }
                    showEditor = false
                },
                onCancel: {
                    showEditor = false
                }
            )
        }
    }
}
```

---

## Implementation Phases

### PHASE 1: Foundation (Weeks 1-2)
**Goal**: Basic text overlay editor on static images

**Tasks**:
- [ ] Set up Swift Package with proper dependencies
- [ ] Create data models (TextLayer, LayerPosition, TextLayerStyle, etc.)
- [ ] Create `MediaCanvasView` (image background + overlay container)
- [ ] Create `TextLayerView` (draggable, rotatable, scalable text)
  - Drag gesture to reposition
  - Pinch gesture to scale
  - Rotation gesture
- [ ] Create `AnimatedPostEditorView` container
  - Photo picker integration (delegate to Loxation's PHMediaPicker)
  - Add text button → creates new `TextLayer`
  - Layer list UI (show/hide, delete, reorder z-index)
- [ ] Create `TextLayerEditorSheet`
  - Text input field
  - Font/size/color/style pickers
  - Shadow/outline toggles
  - Preview

**Deliverable**: Static image with editable text overlays (no animations yet)

---

### PHASE 2: Animation Presets (Weeks 3-4)
**Goal**: Add entrance/exit animations with preset gallery

**Tasks**:
- [ ] Create `AnimationPresetPicker` gallery view
  - Visual thumbnails for each preset
  - Preview animation on tap
  - Organized by category (entrance, exit, loop)
- [ ] Implement `AnimationRenderer` service
  - `fadeIn`, `fadeSlideUp`, `zoomIn`, `bounceIn` presets
  - `fadeOut`, `slideOutUp`, `zoomOut` presets
  - `pulse`, `bounce`, `float` looping presets
  - Use SwiftUI `.animation()` + `.transition()` modifiers
- [ ] Create `AnimatedPostPlayerView`
  - Play button overlay on canvas
  - Timeline scrubber (for images: animation timeline)
  - Layer visibility toggles
  - Export button
- [ ] Wire up animation timing
  - Delay controls (when does animation start)
  - Duration controls (how long animation lasts)
  - Loop toggle

**Deliverable**: Images with animated text overlays (preset animations)

---

### PHASE 3: Video Support (Weeks 5-7)
**Goal**: Extend to videos with synchronized text animations

**Tasks**:
- [ ] Create `VideoCompositor` service
  - Wrap AVPlayer for video playback
  - Time observer for synchronization
  - Overlay rendering with CALayer
- [ ] Extend `MediaCanvasView` for video
  - Use `VideoPlayer` with overlay parameter
  - Playback controls (play/pause, scrubber)
  - Thumbnail extraction for preview
- [ ] Synchronize text animations to video timeline
  - Text layers appear/disappear at specified times
  - Animations loop with video loop
  - Scrubbing updates animation state
- [ ] Video export (optional)
  - Use AVVideoComposition to burn in text
  - Export as MP4 for Loxation's Cloudflare Stream upload
  - Progress indicator

**Deliverable**: Videos with synchronized animated text overlays

---

### PHASE 4: Path Animations (Weeks 8-10)
**Goal**: Motion along curved paths + text along curves

**Tasks**:
- [ ] Create `PathDrawingView`
  - Finger drawing creates Bezier curve
  - Control point editing
  - Curve smoothing algorithm
  - Visual feedback (path preview)
- [ ] Implement path-based animations
  - `motionPath` preset: Text follows drawn path
  - Use `CAKeyframeAnimation` with UIBezierPath
  - Timing function (ease-in/out)
- [ ] Implement shaped text (text along curve)
  - Position each letter along arc/circle/wave
  - Rotate letters to follow tangent
  - Presets: circular, arc, wave
- [ ] Path editor UI
  - Draw path mode
  - Edit control points mode
  - Delete/clear path
  - Path presets (heart, star, spiral)

**Deliverable**: Text animations along custom drawn paths + curved text shapes

---

### PHASE 5: Polish & Export (Weeks 11-12)
**Goal**: Production-ready with HTML export

**Tasks**:
- [ ] Create `HTMLAnimationExporter`
  - Parse `RichPostContent` JSON
  - Generate HTML structure
  - Generate CSS animations (keyframes)
  - Generate JavaScript for complex paths (use GSAP or Anime.js)
  - Standalone HTML file or embeddable snippet
- [ ] UI polish
  - Preset gallery thumbnails (generate previews)
  - Onboarding tutorial
  - Templates (pre-built layouts)
  - Empty state / help text
- [ ] Performance optimization
  - Lazy load video frames
  - Optimize animation rendering
  - Reduce memory footprint
- [ ] Error handling
  - Upload failures
  - Unsupported media formats
  - Animation complexity limits
- [ ] Testing
  - Unit tests for animation calculations
  - UI tests for editor workflow
  - End-to-end tests (create → export → render)

**Deliverable**: Production-ready animated post editor with HTML export

---

### PHASE 6: Advanced Features (Weeks 13-14)
**Goal**: Lottie integration + advanced capabilities

**Tasks**:
- [ ] Lottie import support
  - File picker for .json files
  - Parse Lottie JSON format
  - Render with lottie-ios library
  - Map to `RichPostBlock` if possible
- [ ] Animation templates
  - Pre-built animated post layouts
  - Category browser (birthday, travel, food, etc.)
  - One-tap apply template
- [ ] Advanced text effects
  - Gradient text colors
  - Texture fills (image/pattern)
  - Animated gradients
  - Character-by-character animations
- [ ] Layer effects
  - Blur animations
  - Glow effects
  - Particles (confetti, sparkles)

**Deliverable**: Professional-grade feature set rivaling Instagram/TikTok

---

## Component Specifications

### 1. AnimatedPostEditorView.swift (PUBLIC API)

**Purpose**: Main container for editing animated posts

**UI Layout**:
```
┌─────────────────────────────────────┐
│ [Cancel]  Animated Post   [Export]  │ ← Navigation bar
├─────────────────────────────────────┤
│                                      │
│     ┌─────────────────────┐         │
│     │                     │         │
│     │  [Media Canvas]     │         │ ← MediaCanvasView
│     │                     │         │
│     │  🔤 Text Layer 1    │         │
│     │  🔤 Text Layer 2    │         │
│     │                     │         │
│     └─────────────────────┘         │
│                                      │
│ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━       │ ← Video scrubber (if video)
│                                      │
├─────────────────────────────────────┤
│ Layers:                              │
│ [👁 Layer 1] [👁 Layer 2] [+ Add]   │ ← Layer chips
├─────────────────────────────────────┤
│ [▶️ Play] [🎨 Style] [✨ Animate]   │ ← Bottom toolbar
└─────────────────────────────────────┘
```

**State**:
```swift
@StateObject private var viewModel = AnimatedPostEditorViewModel()
@State private var selectedLayerId: UUID? = nil
@State private var isPlaying = false
@State private var showTextEditor = false
@State private var showAnimationPicker = false
@State private var showPathDrawer = false
```

---

### 2. MediaCanvasView.swift

**Purpose**: Display media (image/video) with text layer overlays

**For Images**:
```swift
struct MediaCanvasView: View {
    let mediaURL: URL
    let textLayers: [TextLayer]
    @Binding var selectedLayerId: UUID?
    let onLayerTap: (UUID) -> Void

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background media
                AsyncImage(url: mediaURL) { image in
                    image.resizable().scaledToFit()
                } placeholder: {
                    ProgressView()
                }

                // Text layers
                ForEach(textLayers) { layer in
                    TextLayerView(
                        layer: layer,
                        canvasSize: geometry.size,
                        isSelected: selectedLayerId == layer.id,
                        onTap: { onLayerTap(layer.id) }
                    )
                }
            }
        }
        .aspectRatio(9/16, contentMode: .fit)  // Instagram Stories ratio
    }
}
```

**For Videos**:
```swift
VideoPlayer(player: AVPlayer(url: mediaURL)) {
    // Overlay text layers
    ForEach(textLayers) { layer in
        TextLayerView(
            layer: layer,
            canvasSize: geometry.size,
            playbackTime: player.currentTime,  // For sync
            isSelected: selectedLayerId == layer.id,
            onTap: { onLayerTap(layer.id) }
        )
    }
}
```

---

### 3. TextLayerView.swift

**Purpose**: Draggable, rotatable, scalable text overlay

**Gestures**:
- **Drag**: Reposition layer
- **Pinch**: Scale up/down
- **Rotation**: Rotate around center
- **Tap**: Select layer

**Implementation**:
```swift
struct TextLayerView: View {
    let layer: TextLayer
    let canvasSize: CGSize
    let isSelected: Bool
    let onTap: () -> Void

    @State private var position: CGPoint
    @State private var scale: CGFloat
    @State private var rotation: Angle

    var body: some View {
        Text(layer.text)
            .font(fontForStyle(layer.style))
            .foregroundColor(Color(hex: layer.style.color))
            .bold(layer.style.bold)
            .italic(layer.style.italic)
            .shadow(
                color: Color(hex: layer.style.shadow?.color ?? "#000000")
                    .opacity(layer.style.shadow?.opacity ?? 0),
                radius: layer.style.shadow?.radius ?? 0,
                x: layer.style.shadow?.offset.width ?? 0,
                y: layer.style.shadow?.offset.height ?? 0
            )
            .scaleEffect(scale)
            .rotationEffect(rotation)
            .position(absolutePosition)
            .overlay(
                isSelected ?
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.blue, lineWidth: 2)
                        .padding(-8)
                    : nil
            )
            .gesture(dragGesture)
            .gesture(magnificationGesture)
            .gesture(rotationGesture)
            .onTapGesture(perform: onTap)
    }

    private var absolutePosition: CGPoint {
        CGPoint(
            x: layer.position.x * canvasSize.width,
            y: layer.position.y * canvasSize.height
        )
    }
}
```

---

### 4. AnimationPresetPicker.swift

**Purpose**: Visual gallery of animation presets

**UI**:
```
┌─────────────────────────────────────┐
│ Animation Presets                    │
├─────────────────────────────────────┤
│ Entrance:                            │
│ [Fade In] [Slide Up] [Zoom] [Bounce]│ ← Animated previews
├─────────────────────────────────────┤
│ Exit:                                │
│ [Fade Out] [Slide Out] [Zoom Out]   │
├─────────────────────────────────────┤
│ Loop:                                │
│ [Pulse] [Bounce] [Float] [Wiggle]   │
├─────────────────────────────────────┤
│ Path:                                │
│ [Motion Path] [Curve Path]           │
└─────────────────────────────────────┘
```

---

### 5. AnimationRenderer.swift

**Purpose**: Execute animations on TextLayerView

**Core Logic**:
```swift
struct AnimationRenderer {
    static func animate(
        layer: TextLayer,
        preset: AnimationPreset,
        onView view: some View
    ) -> some View {
        switch preset {
        case .fadeIn:
            return view
                .opacity(0)
                .onAppear {
                    withAnimation(.easeIn(duration: layer.animation?.duration ?? 0.8)) {
                        view.opacity(1)
                    }
                }

        case .fadeSlideUp:
            return view
                .opacity(0)
                .offset(y: 50)
                .onAppear {
                    withAnimation(.easeOut(duration: layer.animation?.duration ?? 0.8)) {
                        view.opacity(1)
                        view.offset(y: 0)
                    }
                }

        case .pulse:
            return view.modifier(PulseAnimation(isAnimating: true))

        case .motionPath:
            return view.modifier(
                PathAnimation(
                    path: layer.path,
                    duration: layer.animation?.duration ?? 2.0
                )
            )

        default:
            return view
        }
    }
}
```

---

### 6. HTMLAnimationExporter.swift

**Purpose**: Convert JSON animation data to HTML/CSS/JS

**Output Format**: Standalone HTML file or embeddable snippet

**Implementation**:
```swift
struct HTMLAnimationExporter {
    func export(content: RichPostContent) -> String {
        var html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Animated Post</title>
            <style>
                body { margin: 0; padding: 0; background: #000; }
                .canvas {
                    position: relative;
                    width: 100vw;
                    max-width: 500px;
                    aspect-ratio: 9 / 16;
                    margin: 0 auto;
                    overflow: hidden;
                }
                .media {
                    width: 100%;
                    height: 100%;
                    object-fit: cover;
                }
                .text-layer {
                    position: absolute;
                    white-space: pre-wrap;
                    pointer-events: none;
                }
        """

        // Generate CSS keyframe animations
        for block in content.blocks {
            if let textLayers = block.textLayers {
                for layer in textLayers {
                    html += generateCSSAnimation(for: layer)
                }
            }
        }

        html += """
            </style>
        </head>
        <body>
            <div class="canvas">
        """

        // Generate HTML structure
        for block in content.blocks {
            if let imageURL = block.url, block.image != nil {
                html += "<img src=\"\(imageURL)\" class=\"media\" />\n"
            } else if let videoURL = block.url, block.video != nil {
                html += "<video src=\"\(videoURL)\" class=\"media\" autoplay loop muted playsinline></video>\n"
            }

            if let textLayers = block.textLayers {
                for layer in textLayers {
                    html += generateTextLayerHTML(for: layer)
                }
            }
        }

        html += """
            </div>
            <script src="https://cdnjs.cloudflare.com/ajax/libs/gsap/3.11.4/gsap.min.js"></script>
            <script>
        """

        // Generate JavaScript for complex animations (paths)
        for block in content.blocks {
            if let textLayers = block.textLayers {
                for layer in textLayers {
                    if let animation = layer.animation {
                        html += generateJavaScriptAnimation(for: layer, animation: animation)
                    }
                }
            }
        }

        html += """
            </script>
        </body>
        </html>
        """

        return html
    }
}
```

---

## Technical Research

### Video Playback with Text Overlays
- **SwiftUI VideoPlayer** supports overlay parameter for custom views on top of video
- **AVPlayer + CALayer** provides precise control for synchronized animations
- **Time observers** enable synchronization between video playback and text animations
- **Sources**:
  - [SwiftUI AVPlayer Integration](https://medium.com/@tokusha.aa/mastering-swiftui-and-avplayer-integration-a-complete-guide-to-timecodes-and-advanced-playback-6ef9a88b3b8d)
  - [Playing Video with AVPlayer](https://benoitpasquier.com/playing-video-avplayer-swiftui/)

### Path-Based Text Animation
- **UIBezierPath + CAKeyframeAnimation** for motion along curves
- Set bezier curve to `animation.path` property, animate position
- **Important**: Start and end paths must have same number of control points
- **Sources**:
  - [Bezier Curves with Core Animation](https://medium.com/@cboynton/your-and-my-first-bezier-curve-with-core-animation-433a87b0a679)
  - [Animate Bezier Paths](https://novinfard.medium.com/creating-custom-shapes-using-bezier-paths-and-animate-them-by-cabasicanimation-in-ios-f26355c2538b)

### Text Along Curved Paths (Shaped Typography)
- Position each letter along imaginary circle/arc
- Rotate letters to follow curve tangent
- **Available library**: [CurvyText for SwiftUI](https://github.com/rnapier/CurvyText)
- **Sources**:
  - [Circular Text in SwiftUI](https://medium.com/@garejakirit/how-to-create-circular-or-arc-text-in-swiftui-d00d8f3b612e)
  - [Circular Text Path](https://designcode.io/swiftui-handbook-circular-text-path/)

### Cross-Platform Animation Format
- **Lottie/Bodymovin**: Industry standard JSON animation format
- **After Effects → Bodymovin plugin → JSON** → Lottie renderers (iOS + web)
- **Used by**: Instagram, TikTok, Airbnb for cross-platform animations
- **Sources**:
  - [Lottie iOS](https://github.com/airbnb/lottie-ios)
  - [Lottie Web](https://github.com/airbnb/lottie-web)
  - [Bodymovin Plugin](https://aescripts.com/bodymovin/)

---

## Testing Strategy

### Manual Testing

1. **Basic Workflow**
   - [ ] Select photo from library → opens editor
   - [ ] Add text layer → appears on canvas
   - [ ] Drag text → position updates
   - [ ] Pinch text → scale changes
   - [ ] Rotate text → rotation applies
   - [ ] Edit text style → preview updates
   - [ ] Pick animation preset → preview plays
   - [ ] Export → generates JSON

2. **Animation Testing**
   - [ ] Fade in → text appears smoothly
   - [ ] Slide up → text enters from bottom
   - [ ] Zoom in → text scales from small
   - [ ] Bounce → spring animation works
   - [ ] Pulse (loop) → continuously scales
   - [ ] Motion path → text follows curve

3. **Video Testing**
   - [ ] Select video → plays in canvas
   - [ ] Add text → overlays on video
   - [ ] Play button → animations sync with video
   - [ ] Scrub timeline → text appears/disappears at correct times
   - [ ] Export → JSON includes video reference

4. **HTML Export Testing**
   - [ ] Export simple post → generates valid HTML
   - [ ] Open in browser → renders correctly
   - [ ] Animations play → CSS keyframes work
   - [ ] Path animations → GSAP executes
   - [ ] Responsive → works on mobile/desktop

### Automated Testing

```swift
// Example unit test
class AnimationRendererTests: XCTestCase {
    func testFadeInAnimation() {
        let layer = TextLayer(
            id: UUID(),
            text: "Test",
            position: LayerPosition(x: 0.5, y: 0.5),
            style: TextLayerStyle(),
            animation: TextAnimation(
                preset: .fadeIn,
                duration: 0.8
            )
        )

        // Test animation logic
        // Assert opacity changes from 0 to 1
        // Assert duration is 0.8 seconds
    }

    func testPathAnimation() {
        let path = AnimationPath(
            type: .bezier,
            points: [
                CGPoint(x: 0.1, y: 0.1),
                CGPoint(x: 0.5, y: 0.9),
                CGPoint(x: 0.9, y: 0.1)
            ],
            curveType: .quadratic
        )

        // Test path calculation
        // Assert curve generation
        // Assert keyframe positions
    }
}
```

---

## Performance Considerations

1. **Video Playback**
   - Use AVPlayer for efficient hardware-accelerated playback
   - Limit simultaneous text layers (max 10)
   - Optimize CALayer composition

2. **Animation Rendering**
   - Use SwiftUI's built-in animation engine (GPU-accelerated)
   - Avoid complex path animations on low-end devices
   - Provide "reduce motion" accessibility option

3. **Memory Management**
   - Release video memory when not playing
   - Cache animation calculations
   - Limit undo/redo stack depth

4. **Export Performance**
   - HTML generation is fast (string concatenation)
   - Compress generated HTML (minify CSS/JS)
   - Limit path point count (max 50 points)

---

## Timeline Estimates

| Phase | Duration | Deliverable |
|-------|----------|-------------|
| 1: Foundation | 2 weeks | Text overlays on images |
| 2: Animation Presets | 2 weeks | Animated text with presets |
| 3: Video Support | 3 weeks | Video + synced text animations |
| 4: Path Animations | 3 weeks | Motion paths + curved text |
| 5: Polish & Export | 2 weeks | HTML export + production ready |
| 6: Advanced Features | 2 weeks | Lottie + templates |
| **TOTAL** | **14 weeks** | **Instagram/TikTok-quality editor** |

---

## Future Enhancements (Post-MVP)

1. **Timeline Editor** (TikTok-style)
   - Horizontal timeline with layer tracks
   - Keyframe editing
   - Precise timing control
   - Multi-layer synchronization

2. **Effects Library**
   - Blur animations
   - Glow/neon effects
   - Particle systems (confetti, sparkles)
   - Gradient text animations

3. **Smart Templates**
   - AI-suggested layouts based on media
   - Category-based templates (birthday, travel, food)
   - One-tap apply + customize

4. **Collaboration**
   - Share draft JSON
   - Collaborative editing
   - Remix others' posts

5. **Desktop Creator**
   - macOS app using same JSON format
   - Larger canvas for precise editing
   - Pro features (timeline, keyframes)

6. **Lottie Export**
   - Convert custom animations to Lottie format
   - Use in other tools (After Effects, Figma)

---

## References

**Technical Documentation**:
- [SwiftUI AVPlayer Integration](https://medium.com/@tokusha.aa/mastering-swiftui-and-avplayer-integration-a-complete-guide-to-timecodes-and-advanced-playback-6ef9a88b3b8d)
- [Playing Video with AVPlayer in SwiftUI](https://benoitpasquier.com/playing-video-avplayer-swiftui/)
- [Bezier Curves with Core Animation](https://medium.com/@cboynton/your-and-my-first-bezier-curve-with-core-animation-433a87b0a679)
- [CAKeyframeAnimation Tutorial](https://novinfard.medium.com/creating-custom-shapes-using-bezier-paths-and-animate-them-by-cabasicanimation-in-ios-f26355c2538b)
- [Circular Text in SwiftUI](https://medium.com/@garejakirit/how-to-create-circular-or-arc-text-in-swiftui-d00d8f3b612e)
- [CurvyText Library](https://github.com/rnapier/CurvyText)
- [Lottie iOS Documentation](https://github.com/airbnb/lottie-ios)
- [Lottie Web Documentation](https://github.com/airbnb/lottie-web)
- [Bodymovin After Effects Plugin](https://aescripts.com/bodymovin/)

**Design Inspiration**:
- Instagram Stories text editor
- TikTok video effects
- Canva animation presets
- CapCut mobile editor
