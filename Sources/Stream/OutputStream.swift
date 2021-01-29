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

extension OutputStream {
    @inlinable
    public func copyBytes<T: InputStream>(
        from input: T,
        bufferSize: Int = 4096) async throws -> Int
    {
        var total = 0
        var buffer = [UInt8](repeating: 0, count: bufferSize)

        while true {
            let read = try await input.read(to: &buffer)
            guard read > 0 else {
                return total
            }
            total = total &+ read

            var index = 0
            while index < read {
                let written = try await write(from: buffer[index..<read])
                guard written > 0 else {
                    throw StreamError.notEnoughSpace
                }
                index += written
            }
        }
    }
}
