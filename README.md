# RichmediaEditor

A Swift Package for creating Instagram/TikTok-style animated posts with text overlays on photos and videos.

## Features

- **Animated Text Overlays**: Add animated text layers to photos and videos
- **Animation Presets**: Entrance, exit, looping, and path-based animations
- **Rich Text Styling**: Fonts, colors, shadows, outlines, and alignment
- **Path Animations**: Text motion along curved paths
- **HTML Export**: Generate standalone HTML/CSS/JS for web viewing
- **JSON Format**: Compatible with Loxation's richmedia post format

## Requirements

- iOS 16.0+ / macOS 13.0+
- Swift 5.9+
- Xcode 15.0+

## Installation

### Swift Package Manager

Add this package to your Xcode project:

1. File → Add Package Dependencies
2. Enter the repository URL
3. Select version/branch
4. Add to your target

Or add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/YOUR_ORG/richmedia-editor.git", from: "1.0.0")
]
```

## Usage

### Basic Integration

```swift
import SwiftUI
import RichmediaEditor

struct ContentView: View {
    @State private var showEditor = false

    var body: some View {
        Button("Create Animated Post") {
            showEditor = true
        }
        .sheet(isPresented: $showEditor) {
            AnimatedPostEditorView(
                initialMedia: nil,
                onComplete: { richContent in
                    // Handle completed post
                    print("Post created: \(richContent.blocks.count) blocks")
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

### With Initial Media

```swift
// Start with an image
let image = UIImage(named: "photo")!
AnimatedPostEditorView(
    initialMedia: .image(image),
    onComplete: { richContent in
        // Upload and post
    },
    onCancel: {
        // Dismiss
    }
)

// Start with a video
let videoURL = URL(fileURLWithPath: "/path/to/video.mp4")
AnimatedPostEditorView(
    initialMedia: .video(videoURL),
    onComplete: { richContent in
        // Upload and post
    },
    onCancel: {
        // Dismiss
    }
)
```

### Programmatic Post Creation

```swift
import RichmediaEditor

// Create a post programmatically
var content = RichPostContent(version: 1, blocks: [])

// Add image block with text layers
let imageBlock = RichPostBlock(
    image: "photo123",
    url: "https://cdn.example.com/photo123.jpg",
    textLayers: [
        TextLayer(
            text: "Hello World!",
            position: LayerPosition(x: 0.5, y: 0.3),
            style: TextLayerStyle(
                font: "Helvetica",
                size: 48,
                color: "#FFFFFF",
                bold: true
            ),
            animation: TextAnimation(
                preset: .fadeSlideUp,
                duration: 0.8
            )
        )
    ]
)

content.blocks.append(imageBlock)

// Convert to JSON string
if let jsonString = content.toJSONString() {
    print(jsonString)
}
```

## Data Models

### TextLayer

A text overlay layer with position, style, and animation:

```swift
let layer = TextLayer(
    text: "My Text",
    position: LayerPosition(x: 0.5, y: 0.5, rotation: 0, scale: 1.0),
    style: TextLayerStyle(
        font: "Helvetica",
        size: 32,
        color: "#FFFFFF",
        bold: true
    ),
    animation: TextAnimation(preset: .fadeIn, duration: 0.8)
)
```

### Animation Presets

Available animation categories:

- **Entrance**: `fadeIn`, `fadeSlideUp`, `zoomIn`, `bounceIn`, etc.
- **Exit**: `fadeOut`, `slideOutUp`, `zoomOut`
- **Loop**: `pulse`, `bounce`, `float`, `wiggle`, `rotate`
- **Path**: `motionPath`, `curvePath`

```swift
let animation = TextAnimation(
    preset: .pulse,
    delay: 0.5,
    duration: 1.0,
    loop: true,
    loopDelay: 0.2
)
```

### Path Animations

Create custom motion paths:

```swift
let path = AnimationPath(
    type: .bezier,
    points: [
        CGPoint(x: 0.1, y: 0.1),
        CGPoint(x: 0.5, y: 0.9),
        CGPoint(x: 0.9, y: 0.1)
    ],
    curveType: .quadratic
)

let layer = TextLayer(
    text: "Follow Path",
    animation: TextAnimation(preset: .motionPath, duration: 2.0),
    path: path
)
```

## JSON Format

Output format compatible with Loxation richmedia posts:

```json
{
  "version": 1,
  "blocks": [
    {
      "image": "photo123",
      "url": "https://cdn.example.com/photo123.jpg",
      "textLayers": [
        {
          "id": "...",
          "text": "Hello World!",
          "position": {"x": 0.5, "y": 0.3, "rotation": 0, "scale": 1.0},
          "style": {
            "font": "Helvetica",
            "size": 48,
            "color": "#FFFFFF",
            "bold": true
          },
          "animation": {
            "preset": "fadeSlideUp",
            "delay": 0,
            "duration": 0.8,
            "loop": false
          }
        }
      ]
    }
  ]
}
```

## Development Status

### Phase 1: Foundation ✅ (Current)
- ✅ Data models
- ✅ Basic editor view
- ✅ ViewModel state management
- 🚧 Media canvas
- 🚧 Text layer gestures
- ⏳ Style editor

### Phase 2-6: Upcoming
- Animation presets
- Video support
- Path animations
- HTML export
- Advanced features

See [ARCHITECTURE.md](ARCHITECTURE.md) for the complete roadmap.

## Contributing

Contributions are welcome! Please see the architecture document for design decisions and implementation guidelines.

## License

[Your License Here]

## Credits

Built for the Loxation decentralized messaging platform.
