import PackageDescription

let package = Package(
    name: "Stream",
    dependencies: [
        .Package(url: "https://github.com/swift-stack/test.git", majorVersion: 0),
    ]
)
