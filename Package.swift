// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "goose",
    platforms: [ .macOS(.v11) ],
    dependencies: [
        .package(url: "https://github.com/bow-swift/bow.git", from: "0.8.0"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "0.3.0"),
        .package(path: "../Tea"),
    ],
    targets: [
        .executableTarget(
            name: "goose",
            dependencies: [
                .product(name: "BowEffects", package: "bow"),
                "GitLib",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                "Tea"
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
