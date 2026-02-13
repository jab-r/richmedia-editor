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
        // Phase 6: Lottie for professional animations
        .package(url: "https://github.com/airbnb/lottie-ios.git", from: "4.4.0"),
    ],
    targets: [
        .target(
            name: "RichmediaEditor",
            dependencies: [
                .product(name: "Lottie", package: "lottie-ios"),
            ],
            path: "Sources/RichmediaEditor",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "RichmediaEditorTests",
            dependencies: ["RichmediaEditor"],
            path: "Tests/RichmediaEditorTests"
        ),
    ]
)
