// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "EmojiPalette",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16),
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "EmojiPalette",
            targets: ["EmojiPalette"]
        )
    ],
    targets: [
        .target(
            name: "EmojiPalette",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "EmojiPaletteTests",
            dependencies: ["EmojiPalette"]
        )
    ]
)
