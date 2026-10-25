// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "ReadingKit",
    platforms: [
        .iOS(.v26),
        .macOS(.v15)
    ],
    products: [
        .library(name: "ReadingCore", targets: ["ReadingCore"]),
        .library(name: "ReadingStore", targets: ["ReadingStore"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "ReadingCore",
            resources: [
                .process("Resources")
            ]
        ),
        .target(
            name: "ReadingStore",
            dependencies: ["ReadingCore"]
        ),
        .testTarget(
            name: "ReadingCoreTests",
            dependencies: ["ReadingCore"]
        ),
        .testTarget(
            name: "ReadingStoreTests",
            dependencies: ["ReadingStore"]
        )
    ]
)
