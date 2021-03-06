extension OutputByteStream: StreamWriter {
    public var buffered: Int {
        return bytes.count - position
    }

    public func write(_ byte: UInt8) throws {
        bytes.append(byte)
    }

    public func write<T: FixedWidthInteger>(_ value: T) throws {
        var value = value.bigEndian
        withUnsafeBytes(of: &value) { buffer in
            bytes.append(contentsOf: buffer)
        }
    }

    public func write(_ bytes: UnsafeRawPointer, byteCount: Int) throws {
        var written = 0
        while written < byteCount {
            let count = try write(from: bytes, byteCount: byteCount)
            guard count > 0 else {
                throw StreamError.insufficientData
            }
            written += count
        }
    }

    // MARK: Override StreamWriter async functions

    public func write(_ bytes: UnsafeRawBufferPointer) throws {
        try write(bytes.baseAddress!, byteCount: bytes.count)
    }

    public func write(_ bytes: [UInt8]) throws {
        try write(bytes, byteCount: bytes.count)
    }

    public func write(_ string: String) throws {
        try write([UInt8](string.utf8))
    }

    public func flush() throws {}
}
