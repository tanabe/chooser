// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "chooser",
    dependencies: [
        .package(
            url: "https://github.com/apple/swift-argument-parser",
            from: "1.0.3"),
    ],
    targets: [
        .target(
            name: "chooser",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]),
        .testTarget(
            name: "chooserTests",
            dependencies: ["chooser"]),
    ]
)
