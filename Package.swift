// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "SpringInterpolation",
    platforms: [
        .iOS(.v13),
        .macOS(.v11),
        .macCatalyst(.v13),
        .tvOS(.v13),
        .visionOS(.v1),
    ],
    products: [
        .library(
            name: "SpringInterpolation",
            targets: ["SpringInterpolation"],
        ),
    ],
    targets: [
        .target(name: "SpringInterpolation"),
    ],
)
