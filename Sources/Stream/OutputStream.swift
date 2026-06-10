public protocol OutputStream {
    func write(
        from buffer: UnsafeRawPointer,
        byteCount: Int
    ) async throws(StreamError) -> Int
}
