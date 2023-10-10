// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "chooser",
    platforms: [
        .macOS(.v10_15),
    ],
    dependencies: [
        .package(
            url: "https://github.com/apple/swift-argument-parser",
            from: "1.2.3"),
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
