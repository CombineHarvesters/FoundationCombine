// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "Publishers",
    products: [
        .library(
            name: "Publishers",
            targets: ["Publishers"]),
    ],
    targets: [
        .target(
            name: "Publishers"),
        .testTarget(
            name: "PublishersTests",
            dependencies: ["Publishers"]),
    ]
)
