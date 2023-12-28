// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "swift-otel-xray",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "OpenTelemetryXRay", targets: ["OpenTelemetryXRay"]),
    ],
    dependencies: [
        .package(url: "https://github.com/slashmo/swift-otel.git", branch: "main"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.0.0"),
    ],
    targets: [
        .target(name: "OpenTelemetryXRay", dependencies: [
            .product(name: "NIOConcurrencyHelpers", package: "swift-nio"),
            .product(name: "OTel", package: "swift-otel"),
        ]),
        .testTarget(name: "OpenTelemetryXRayTests", dependencies: [
            .target(name: "OpenTelemetryXRay"),
        ]),
    ]
)
