// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "ClipBord",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .executable(name: "ClipBord", targets: ["ClipBord"]),
    ],
    targets: [
        .executableTarget(
            name: "ClipBord"
        ),
    ]
)
