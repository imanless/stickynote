// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "StickyNote",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "StickyNote", targets: ["StickyNote"])
    ],
    targets: [
        // UI-free model and persistence, kept separate so it can be unit tested.
        .target(name: "StickyNoteCore"),
        .executableTarget(
            name: "StickyNote",
            dependencies: ["StickyNoteCore"]
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
