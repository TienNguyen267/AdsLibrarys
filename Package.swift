// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "AdsLibraryPackage",

    platforms: [
        .iOS(.v15)
    ],

    products: [
        .library(
            name: "AdsLibrary",
            targets: ["AdsLibrary"]
        )
    ],

    targets: [
        .binaryTarget(
            name: "AdsLibrary",
            path: "./AdsLibrary.xcframework"
        )
    ]
)
