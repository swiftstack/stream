extension ByteArrayOutputStream: StreamWriter {
    public var buffered: Int {
        return bytes.count - position
    }

    public func write(_ byte: UInt8) {
        bytes.append(byte)
    }

    public func write<T: FixedWidthInteger>(_ value: T) {
        var value = value.bigEndian
        withUnsafeBytes(of: &value) { buffer in
            bytes.append(contentsOf: buffer)
        }
    }

    public func write(_ bytes: UnsafeRawPointer, byteCount: Int) {
        _ = write(from: bytes, byteCount: byteCount)
    }

    // MARK: Override StreamWriter async functions

    public func write(_ bytes: UnsafeRawBufferPointer) {
        write(bytes.baseAddress!, byteCount: bytes.count)
    }

    public func write(_ bytes: [UInt8]) {
        write(bytes, byteCount: bytes.count)
    }

    public func write(_ string: String) {
        write([UInt8](string.utf8))
    }

    public func flush() {}
}
