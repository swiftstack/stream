extension BufferedOutputStream: StreamWriter {
    public func write(_ byte: UInt8) throws {
        if available <= 0 {
            try flush()
        }
        storage.advanced(by: buffered)
            .assumingMemoryBound(to: UInt8.self)
            .pointee = byte
        buffered += 1
    }

    @inlinable
    public func write<T: FixedWidthInteger>(_ value: T) throws {
        var value = value.bigEndian
        return try withUnsafePointer(to: &value) { pointer in
            return try write(pointer, byteCount: MemoryLayout<T>.size)
        }
    }

    public func write(_ buffer: UnsafeRawPointer, byteCount: Int) throws {
        var written = 0
        while written < byteCount {
            let count: Int = try write(from: buffer, byteCount: byteCount)
            guard count > 0 else {
                throw StreamError.insufficientData
            }
            written += count
        }
    }
}
