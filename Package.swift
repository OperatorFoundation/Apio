// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Apio",
    
    platforms: [.macOS(.v13)],
    
    products: [
        .library(
            name: "Apio",
            targets: ["Apio"]),
    ],
    
    dependencies: [
        .package(url: "https://github.com/OperatorFoundation/Gardener", branch: "main")
    ],
    
    targets: [
        .target(
            name: "Apio",
            dependencies: ["Gardener"]),
        .testTarget(
            name: "ApioTests",
            dependencies: ["Apio"]),
    ],
    
    swiftLanguageVersions: [.v5]
)
