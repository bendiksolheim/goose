// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "goose",
    platforms: [ .macOS(.v10_14) ],
    dependencies: [
        .package(path: "../../github-external/Termbox"),
        .package(url: "https://github.com/bow-swift/bow.git", from: "0.7.0"),
        .package(url: "https://github.com/ReactiveCocoa/ReactiveSwift.git", from: "6.1.0"),
        .package(url: "https://github.com/davedufresne/SwiftParsec", .branch("master"))
    ],
    targets: [
        .target(
            name: "goose",
            dependencies: ["BowEffects", "GitLib", "Tea"]),
        .target(
            name: "GitLib",
            dependencies: ["BowEffects", "SwiftParsec"]),
        .target(
            name: "Tea",
            dependencies: ["ReactiveSwift", "Termbox"]),
        .testTarget(
            name: "GitLibTests",
            dependencies: ["GitLib", "BowEffects"]),
    ]
)
