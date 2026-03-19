// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Shotty",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "Shotty",
            targets: ["Shotty"]
        )
    ],
    targets: [
        .executableTarget(
            name: "Shotty",
            resources: [
                .process("Resources")
            ],
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("Carbon"),
                .linkedFramework("CoreGraphics"),
                .linkedFramework("ScreenCaptureKit"),
                .linkedFramework("Vision")
            ]
        )
    ]
)
