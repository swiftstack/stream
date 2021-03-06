// swift-tools-version:5.4
import PackageDescription

let package = Package(
    name: "Stream",
    products: [
        .library(name: "Stream", targets: ["Stream"])
    ],
    dependencies: [
        .package(name: "Test")
    ],
    targets: [
        .target(
            name: "Stream",
            swiftSettings: [
                .unsafeFlags(["-Xfrontend", "-enable-experimental-concurrency"])
            ])
    ]
)

// MARK: - tests

addTestSuite(name: "Stream/BufferedInputStream")
addTestSuite(name: "Stream/BufferedOutputStream")
addTestSuite(name: "Stream/BufferedStream")
addTestSuite(name: "Stream/BufferedStreamReader")
addTestSuite(name: "Stream/BufferedStreamWriter")
addTestSuite(name: "Stream/InputByteStream")
addTestSuite(name: "Stream/MemoryStream")
addTestSuite(name: "Stream/Numeric")
addTestSuite(name: "Stream/OutputByteStream")
addTestSuite(name: "Stream/Stream")
addTestSuite(name: "Stream/StreamReader")
addTestSuite(name: "Stream/SubStreamReader")
addTestSuite(name: "Stream/SubStreamWriter")

func addTestSuite(name: String) {
    package.targets.append(
        .executableTarget(
            name: "Tests/" + name,
            dependencies: ["Stream", "Test"],
            path: "Tests/" + name,
            swiftSettings: [
                .unsafeFlags(["-Xfrontend", "-enable-experimental-concurrency"])
            ]))
}

// MARK: - custom package source

#if canImport(ObjectiveC)
import Darwin.C
#else
import Glibc
#endif

extension Package.Dependency {
    enum Source: String {
        case local, remote, github

        static var `default`: Self { .local }

        var baseUrl: String {
            switch self {
            case .local: return "../"
            case .remote: return "https://swiftstack.io/"
            case .github: return "https://github.com/swift-stack/"
            }
        }

        func url(for name: String) -> String {
            return self == .local
                ? baseUrl + name.lowercased()
                : baseUrl + name.lowercased() + ".git"
        }
    }

    static func package(name: String) -> Package.Dependency {
        guard let pointer = getenv("SWIFTSTACK") else {
            return .package(name: name, source: .default)
        }
        guard let source = Source(rawValue: String(cString: pointer)) else {
            fatalError("Invalid source. Use local, remote or github")
        }
        return .package(name: name, source: source)
    }

    static func package(name: String, source: Source) -> Package.Dependency {
        return source == .local
            ? .package(name: name, path: source.url(for: name))
            : .package(name: name, url: source.url(for: name), .branch("dev"))
    }
}
