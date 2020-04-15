// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "magit",
    platforms: [ .macOS(.v10_14) ],
    dependencies: [
        // .package(url: /* package url */, from: "1.0.0"),
      // .package(url: "https://github.com/colinta/Ashen.git", .branch("master"))
        //.package(path: "../../github-external/Ashen"),
        .package(path: "../../github-external/Termbox"),
        .package(url: "https://github.com/bow-swift/bow.git", from: "0.7.0"),
        .package(url: "https://github.com/ReactiveCocoa/ReactiveSwift.git", from: "6.1.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "magit",
            dependencies: ["GitLib", "Termbox", "BowEffects", "ReactiveSwift"]),
        .target(
            name: "GitLib",
            dependencies: ["BowEffects"]),
        .testTarget(
            name: "GitLibTests",
            dependencies: ["GitLib", "BowEffects"]),
    ]
)
