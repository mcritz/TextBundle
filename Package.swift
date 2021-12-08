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
        .package(url: "https://github.com/weichsel/ZIPFoundation", .upToNextMajor(from: "0.9.0")),
    ],
    targets: [
        .target(
            name: "TextBundle",
            dependencies: [
                "ZIPFoundation"
            ]
        ),
        .testTarget(
            name: "TextBundleTests",
            dependencies: ["TextBundle"],
            resources: [
                .process("Resources/white_rabbit.jpg")
            ]
        ),
    ]
)
