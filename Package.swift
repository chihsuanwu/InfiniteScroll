// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "InfiniteScroll",
    platforms: [
        .iOS(.v14),
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "InfiniteScroll",
            targets: ["InfiniteScroll"]),
    ],
    dependencies: [
        .package(url: "https://github.com/chihsuanwu/HuggingGeometryReader.git", from: "0.1.0")
    ],
    targets: [
        .target(
            name: "InfiniteScroll",
            dependencies: ["HuggingGeometryReader"]),
        .testTarget(
            name: "InfiniteScrollTests",
            dependencies: ["InfiniteScroll"]),
    ]
)
