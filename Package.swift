// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "TextBundle",
    platforms: [
        .macOS(.v10_14),
        .iOS(.v13),
        .tvOS(.v13),
    ],
    products: [
        .library(
            name: "TextBundle",
            targets: ["TextBundle"]),
    ],
    dependencies: [
        .package(url: "https://github.com/marmelroy/Zip.git", .upToNextMajor(from: "2.1.1")),
    ],
    targets: [
        .target(
            name: "TextBundle",
            dependencies: [
                .product(name: "Zip", package: "Zip"),
            ],
            resources: [
                .process("Resources/white_rabbit.jpg")
            ]
        ),
        .testTarget(
            name: "TextBundleTests",
            dependencies: ["TextBundle"],
            resources: [
                .process("Resrouces/white_rabbit.jpg")
            ]
        ),
    ]
)
