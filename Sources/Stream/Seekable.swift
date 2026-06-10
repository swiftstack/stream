public enum SeekOrigin {
    case begin, current, end
}

public protocol Seekable {
    func seek(to offset: Int, from origin: SeekOrigin) async throws(StreamError)
    func seek(to origin: SeekOrigin) async throws(StreamError)
}

public extension Seekable {
    func seek(to origin: SeekOrigin) async throws(StreamError) {
        try await seek(to: 0, from: origin)
    }
}
