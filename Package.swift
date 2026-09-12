// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MacClip",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(name: "MacClip", targets: ["MacClip"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "MacClip",
            dependencies: [],
            path: "Sources/MacClip"
        )
    ]
)
