extension BufferedStream: StreamWriter {
    public func write(_ byte: UInt8) async throws {
        try await outputStream.write(byte)
    }

    public func write<T: FixedWidthInteger>(_ value: T) async throws {
        try await outputStream.write(value)
    }

    public func write(_ bytes: UnsafeRawPointer, byteCount: Int) async throws {
        try await outputStream.write(bytes, byteCount: byteCount)
    }
}
