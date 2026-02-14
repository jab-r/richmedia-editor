# RichmediaEditor

A Swift Package (iOS 16+ / macOS 13+) for creating and viewing richmedia posts with an Instagram/TikTok-style editor. Users compose rich posts by adding text layers, animations, and Lottie overlays on top of photos and videos, with pinch-to-zoom/pan media positioning, then export as JSON.

## Features

- **Canvas-first editing**: Tap text on canvas to select, tap again to edit inline
- **Media transform**: Pinch-to-zoom (1x-5x) and drag-to-pan background media
- **18 animation presets**: Entrance, exit, looping, and path-based animations
- **Rich text styling**: Fonts, colors, shadows, outlines, bold/italic/underline, alignment
- **Path animations**: Draw custom motion paths for text
- **Lottie overlays**: Add animated Lottie stickers on top of media
- **Gallery/carousel support**: Multi-block posts with swipeable pages
- **Gallery player**: Read-only TikTok-style viewer for displaying animated posts
- **Local-first editing**: Edit with local UIImages before upload
- **Cross-platform JSON format**: Output compatible with iOS, Android, and web renderers
- **HTML export**: Server-side rendering at [community.loxation.com](https://community.loxation.com)

## Requirements

- iOS 16.0+ / macOS 13.0+
- Swift 5.9+
- Xcode 15+

## Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/jab-r/richmedia-editor.git", from: "1.0.0")
]
```

Or in Xcode: File > Add Package Dependencies > enter the repository URL.

## Usage

### Editor

```swift
import SwiftUI
import RichmediaEditor

struct ContentView: View {
    @State private var showEditor = false

    var body: some View {
        Button("Create Post") {
            showEditor = true
        }
        .sheet(isPresented: $showEditor) {
            AnimatedPostEditorView(
                initialMedia: .image(myUIImage, url: nil, mediaId: nil),
                onComplete: { richContent, localImages in
                    // richContent: RichPostContent JSON
                    // localImages: [UUID: UIImage] for blocks not yet uploaded
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

### Gallery Player

```swift
GalleryPlayerView(
    content: richPostContent,
    localImages: localImages
)
```

### Programmatic Post Creation

```swift
var content = RichPostContent(version: 1, blocks: [])

let block = RichPostBlock(
    image: "photo123",
    url: "https://cdn.example.com/photo123.jpg",
    textLayers: [
        TextLayer(
            text: "Hello World!",
            position: LayerPosition(x: 0.5, y: 0.3),
            style: TextLayerStyle(font: "Helvetica", size: 48, color: "#FFFFFF", bold: true),
            animation: TextAnimation(preset: .fadeSlideUp, duration: 0.8)
        )
    ],
    mediaTransform: MediaTransform(scale: 1.5, offsetX: 0, offsetY: -20)
)

content.blocks.append(block)

if let json = content.toJSONString() {
    print(json)
}
```

## Animation Presets

- **Entrance**: `fadeIn`, `fadeSlideUp`, `zoomIn`, `bounceIn`, etc.
- **Exit**: `fadeOut`, `slideOutUp`, `zoomOut`
- **Loop**: `pulse`, `bounce`, `float`, `wiggle`, `rotate`
- **Path**: `motionPath`, `curvePath`

## License

[GPL v3](LICENSE)

## Credits

Built for the Loxation decentralized messaging platform.
