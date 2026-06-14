public typealias Stream = InputStream & OutputStream

public protocol InputStream {
    func read(
        to pointer: UnsafeMutableRawPointer,
        byteCount: Int
    ) async throws -> Int
}

public protocol OutputStream {
    func write(
        from buffer: UnsafeRawPointer,
        byteCount: Int
    ) async throws -> Int
}
