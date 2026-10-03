// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "SpringInterpolation",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .macCatalyst(.v15),
        .tvOS(.v15),
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
