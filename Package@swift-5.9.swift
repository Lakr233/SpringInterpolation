// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "SpringInterpolation",
    platforms: [
        .iOS(.v14),
        .macOS(.v11),
        .macCatalyst(.v14),
        .tvOS(.v14),
        .visionOS(.v1),
    ],
    products: [
        .library(
            name: "SpringInterpolation",
            targets: ["SpringInterpolation"]
        ),
    ],
    targets: [
        .target(name: "SpringInterpolation"),
    ]
)
