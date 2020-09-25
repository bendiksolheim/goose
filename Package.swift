// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "goose",
    platforms: [ .macOS(.v10_14) ],
    dependencies: [
        .package(url: "https://github.com/bow-swift/bow.git", from: "0.7.0"),
        .package(url: "https://github.com/davedufresne/SwiftParsec", .branch("master")),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "0.3.0"),
        .package(path: "libraries/tea")
    ],
    targets: [
        .target(
            name: "goose",
            dependencies: ["BowEffects", "GitLib", "ArgumentParser", "tea"]),
        .target(
            name: "GitLib",
            dependencies: ["BowEffects", "SwiftParsec"]),
        .testTarget(
            name: "GitLibTests",
            dependencies: ["GitLib", "BowEffects"]),
    ]
)
