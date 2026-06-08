// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "CloudflareNodeSwitch",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "CloudflareNodeSwitch", targets: ["CloudflareNodeSwitch"])
    ],
    targets: [
        .executableTarget(
            name: "CloudflareNodeSwitch",
            path: "Sources/CloudflareNodeSwitch"
        ),
        .testTarget(
            name: "CloudflareNodeSwitchTests",
            dependencies: ["CloudflareNodeSwitch"],
            path: "Tests/CloudflareNodeSwitchTests"
        )
    ]
)
