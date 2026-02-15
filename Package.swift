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
        .iOS(name: "OpenClawControl", targets: ["OpenClawControl"]),
        .macOS(name: "OpenClawControl", targets: ["OpenClawControl"]),
        .watchKitApp(name: "OpenClawControlWatch", targets: ["OpenClawControlWatch"]),
        .watchKit2Extension(name: "OpenClawControlWatchExtension", targets: ["OpenClawControlWatchExtension"]),
        .xrKitApp(name: "OpenClawControlVision", targets: ["OpenClawControlVision"])
    ],
    targets: [
        // iOS/macOS App
        .target(
            name: "OpenClawControl",
            dependencies: [],
            path: "Sources"
        ),
        
        // watchOS App
        .target(
            name: "OpenClawControlWatch",
            dependencies: ["OpenClawControlWatchExtension"],
            path: "Watch/App"
        ),
        
        // watchOS Extension
        .target(
            name: "OpenClawControlWatchExtension",
            dependencies: [],
            path: "Watch/Extension"
        ),
        
        // visionOS App
        .target(
            name: "OpenClawControlVision",
            dependencies: [],
            path: "Vision/App"
        )
    ]
)
