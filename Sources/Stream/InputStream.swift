public protocol InputStream {
    func read(
        to pointer: UnsafeMutableRawPointer,
        byteCount: Int
    ) async throws -> Int
}
