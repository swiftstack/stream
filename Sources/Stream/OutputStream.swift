public protocol OutputStream {
    func write(
        from buffer: UnsafeRawPointer,
        byteCount: Int
    ) async throws -> Int
}

// @testable
extension OutputStream {
    func write(from buffer: UnsafeRawBufferPointer) async throws -> Int {
        try await write(from: buffer.baseAddress!, byteCount: buffer.count)
    }

    func write(from buffer: [UInt8]) async throws -> Int {
        try await write(from: buffer, byteCount: buffer.count)
    }

    func write(from buffer: ArraySlice<UInt8>) async throws -> Int {
        // [FIXME] Concurrency
        // return try buffer.withUnsafeBytes(write)
        return try await write(from: [UInt8](buffer))
    }
}
