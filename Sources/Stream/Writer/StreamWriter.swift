public protocol StreamWriter: AnyObject {
    func write(_ byte: UInt8) async throws
    func write<T: FixedWidthInteger>(_ value: T) async throws
    func write(_ bytes: [UInt8]) async throws
    func write(_ bytes: UnsafeRawPointer, byteCount: Int) async throws
    func flush() async throws
}

extension StreamWriter {
    public func write(_ bytes: UnsafeRawBufferPointer) async throws {
        try await write(bytes.baseAddress!, byteCount: bytes.count)
    }

    public func write(_ bytes: [UInt8]) async throws {
        try await write(bytes, byteCount: bytes.count)
    }

    public func write(_ string: String) async throws {
        try await write([UInt8](string.utf8))
    }
}

public protocol StreamWritable {
    func write(to stream: StreamWriter) async throws
}
