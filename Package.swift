// swift-tools-version:4.2
import PackageDescription

let package = Package(
    name: "Stream",
    products: [
        .library(name: "Stream", targets: ["Stream"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/swift-stack/test.git",
            .branch("master")
        )
    ],
    targets: [
        .target(name: "Stream"),
        .testTarget(
            name: "StreamTests",
            dependencies: ["Stream", "Test"])
    ]
)
