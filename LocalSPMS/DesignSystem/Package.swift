// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "DesignSystem",
    platforms: [.iOS(.v18), .tvOS(.v18), .watchOS(.v11), .macOS(.v15), .visionOS(.v2)],
    products: [
        .library(
            name: "DesignSystemIFC",
            targets: ["DesignSystemIFC"]
        ),
        .library(
            name: "DesignSystemDefaultIMP",
            targets: ["DesignSystemDefaultIMP"]
        ),
    ],
    targets: [
        .target(
            name: "DesignSystemIFC"
        ),
        .target(
            name: "DesignSystemDefaultIMP",
            dependencies: ["DesignSystemIFC"]
        ),
        .testTarget(
            name: "DesignSystemTests",
            dependencies: ["DesignSystemIFC", "DesignSystemDefaultIMP"]
        ),
    ]
)
