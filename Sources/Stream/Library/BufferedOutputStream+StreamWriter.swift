extension BufferedOutputStream: StreamWriter {
    public func write(_ byte: UInt8) async throws {
        if available <= 0 {
            try await flush()
        }
        storage.advanced(by: buffered)
            .assumingMemoryBound(to: UInt8.self)
            .pointee = byte
        buffered += 1
    }

    public func write<T: FixedWidthInteger>(_ value: T) async throws {
        var value = value.bigEndian
        // FIXME: [Concurrency]
        // return try withUnsafePointer(to: &value) { pointer in
        //     return try await write(pointer, byteCount: MemoryLayout<T>.size)
        // }
        return try await write(&value, byteCount: MemoryLayout<T>.size)
    }

    public func write(_ buffer: UnsafeRawPointer, byteCount: Int) async throws {
        var written = 0
        while written < byteCount {
            let count: Int = try await write(from: buffer, byteCount: byteCount)
            guard count > 0 else {
                throw StreamError.insufficientData
            }
            written += count
        }
    }
}
