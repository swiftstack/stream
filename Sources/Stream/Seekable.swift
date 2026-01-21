public enum SeekOrigin {
    case begin, current, end
}

public protocol Seekable {
    func seek(to offset: Int, from origin: SeekOrigin) async throws
    func seek(to origin: SeekOrigin) async throws
}

public extension Seekable {
    func seek(to origin: SeekOrigin) async throws {
        try await seek(to: 0, from: origin)
    }
}
