// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "FoundationCombine",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(
            name: "FoundationCombine",
            targets: ["FoundationCombine"]),
    ],
    dependencies: [
        .package(url: "https://github.com/CombineHarvesters/CombineTesting", .branch("master"))
    ],
    targets: [
        .target(
            name: "FoundationCombine"),
        .testTarget(
            name: "FoundationCombineTests",
            dependencies: ["FoundationCombine", "CombineTesting"]),
    ]
)
