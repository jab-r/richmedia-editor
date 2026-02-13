// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RichmediaEditor",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "RichmediaEditor",
            targets: ["RichmediaEditor"]),
    ],
    dependencies: [
        // No external dependencies for MVP
        // Future: Add Lottie for Phase 6
        // .package(url: "https://github.com/airbnb/lottie-ios.git", from: "4.0.0"),
    ],
    targets: [
        .target(
            name: "RichmediaEditor",
            dependencies: [],
            path: "Sources/RichmediaEditor"
        ),
        .testTarget(
            name: "RichmediaEditorTests",
            dependencies: ["RichmediaEditor"],
            path: "Tests/RichmediaEditorTests"
        ),
    ]
)
