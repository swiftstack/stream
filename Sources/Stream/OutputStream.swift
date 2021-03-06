public protocol OutputStream {
    func write(
        from buffer: UnsafeRawPointer,
        byteCount: Int
    ) async throws -> Int
}

extension OutputStream {
    @inline(__always)
    public func write(from buffer: UnsafeRawBufferPointer) async throws -> Int {
        return try await write(
            from: buffer.baseAddress!,
            byteCount: buffer.count)
    }

    @inline(__always)
    public func write(from buffer: [UInt8]) async throws -> Int {
        return try await write(from: buffer, byteCount: buffer.count)
    }

    @inline(__always)
    public func write(from buffer: ArraySlice<UInt8>) async throws -> Int {
        // [FIXME] Concurrency
        // return try buffer.withUnsafeBytes(write)
        let buffer = [UInt8](buffer)
        return try await write(from: buffer)
    }
}
