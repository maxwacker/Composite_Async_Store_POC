// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CounterFeature",
    platforms: [.iOS(.v18), .tvOS(.v18), .watchOS(.v11), .macOS(.v15), .visionOS(.v2)],

    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "CounterRedux",
            targets: ["CounterRedux"]
        ),
        .library(
            name: "CounterView",
            targets: ["CounterView"]
        ),
            ],
    dependencies: [
            .package(path:"../ReduxCore"),
            .package(path:"../DesignSystem")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "CounterRedux",
            dependencies: [
                .product(name: "ReduxCoreIFC", package: "ReduxCore")
            ],

        ),
        .target(
            name: "CounterView",
            dependencies: [
                "CounterRedux",
                .product(name: "ReduxCoreIFC", package: "ReduxCore"),
                .product(name: "ReduxCoreIMP", package: "ReduxCore"),
                .product(name: "DesignSystemIFC", package: "DesignSystem"),
                .product(name: "DesignSystemDefaultIMP", package: "DesignSystem")
            ],

        ),
        .testTarget(
            name: "CounterFeatureTests",
            dependencies: ["CounterRedux"]
        ),
    ]
)
