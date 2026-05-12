// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WindManager",
    platforms: [
        .iOS(.v16),
    ],
    products: [
        .library(name: "WindManager", targets: ["WindManager"]),
    ],
    targets: [
        .target(
            name: "WindManager",
            path: "Sources/WindManager"
        ),
        .testTarget(
            name: "WindManagerTests",
            dependencies: ["WindManager"],
            path: "Tests/WindManagerTests"
        ),
    ]
)
