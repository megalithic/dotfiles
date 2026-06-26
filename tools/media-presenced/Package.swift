// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "media-presenced",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "media-presenced",
            path: "Sources/media-presenced"
        )
    ]
)
