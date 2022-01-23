// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "goose",
    platforms: [ .macOS(.v11) ],
    dependencies: [
        .package(url: "https://github.com/bow-swift/bow.git", from: "0.8.0"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "0.3.0"),
        .package(path: "libraries/tea")
    ],
    targets: [
        .target(
            name: "goose",
            dependencies: [
                .product(name: "BowEffects", package: "bow"),
                "GitLib",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                "tea"
            ]),
        .target(
            name: "GitLib",
            dependencies: [
                .product(name: "BowEffects", package: "bow")
            ]),
        .testTarget(
            name: "GitLibTests",
            dependencies: [
                "GitLib",
                .product(name: "BowEffects", package: "bow")
            ]),
    ]
)
