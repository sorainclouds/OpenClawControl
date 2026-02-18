// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "OpenClawControl",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .watchOS(.v10),
        .visionOS(.v1)
    ],
    products: [
        .executable(
            name: "OpenClawControl",
            targets: ["OpenClawControl"]
        )
    ],
    targets: [
        .executableTarget(
            name: "OpenClawControl",
            dependencies: [],
            path: "Sources"
        )
    ]
)
