// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "StickyNote",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "StickyNote", targets: ["StickyNote"])
    ],
    dependencies: [
        // In-app updates. Pinned exactly; Dependabot proposes upgrades.
        .package(url: "https://github.com/sparkle-project/Sparkle", exact: "2.10.0")
    ],
    targets: [
        // UI-free model and persistence, kept separate so it can be unit tested.
        .target(name: "StickyNoteCore"),
        .executableTarget(
            name: "StickyNote",
            dependencies: [
                "StickyNoteCore",
                .product(name: "Sparkle", package: "Sparkle"),
            ]
        ),
        .testTarget(
            name: "StickyNoteCoreTests",
            dependencies: ["StickyNoteCore"]
        ),
        .testTarget(
            name: "StickyNoteTests",
            dependencies: ["StickyNote", "StickyNoteCore"]
        ),
    ]
)
