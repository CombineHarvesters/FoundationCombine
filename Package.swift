// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "Publishers",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(
            name: "Publishers",
            targets: ["Publishers"]),
    ],
    dependencies: [
        .package(url: "https://github.com/CombineHarvesters/CombineTesting", .branch("master"))
    ],
    targets: [
        .target(
            name: "Publishers"),
        .testTarget(
            name: "PublishersTests",
            dependencies: ["Publishers", "CombineTesting"]),
    ]
)
