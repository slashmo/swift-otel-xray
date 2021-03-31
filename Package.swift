// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "opentelemetry-swift-xray",
    dependencies: [
        .package(url: "https://github.com/slashmo/opentelemetry-swift.git", .branch("main")),
    ],
    targets: [
        .target(name: "OpenTelemetryXRay", dependencies: [
            .product(name: "OpenTelemetry", package: "opentelemetry-swift"),
        ]),
        .testTarget(name: "OpenTelemetryXRayTests", dependencies: [
            .target(name: "OpenTelemetryXRay"),
        ]),
    ]
)
