// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ParsePushHelper",
    platforms: [
        .iOS(.v18),
        .macCatalyst(.v18),
        .macOS(.v15)
    ],
    products: [
        .library(name: "ParsePushCore", targets: ["Core"]),
        .library(name: "ParsePushSharedUI", targets: ["SharedUI"])
    ],
    targets: [
        .target(
            name: "Core",
            path: "Sources/Core"
        ),
        .target(
            name: "SharedUI",
            dependencies: ["Core"],
            path: "Sources/SharedUI"
        ),
        .target(
            name: "App",
            dependencies: [
                "Core",
                "SharedUI"
            ],
            path: "Sources/App"
        ),
        .testTarget(
            name: "AppTests",
            dependencies: ["Core"],
            path: "Tests/AppTests"
        ),
        .testTarget(
            name: "SnapshotTests",
            dependencies: [
                "SharedUI",
                "Core"
            ],
            path: "Tests/SnapshotTests"
        ),
        .testTarget(
            name: "UITests",
            dependencies: [
                "SharedUI",
                "Core"
            ],
            path: "Tests/UITests"
        )
    ]
)
