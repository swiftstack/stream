public protocol StreamWriter: AnyObject {
    func write(_ byte: UInt8) async throws(StreamError)
    func write<T: FixedWidthInteger>(_ value: T) async throws(StreamError)
    func write(_ bytes: [UInt8]) async throws(StreamError)
    func write(_ bytes: UnsafeRawPointer, byteCount: Int) async throws(StreamError)
    func flush() async throws(StreamError)
}

extension StreamWriter {
    public func write(_ bytes: UnsafeRawBufferPointer) async throws(StreamError) {
        try await write(bytes.baseAddress!, byteCount: bytes.count)
    }

    public func write(_ bytes: [UInt8]) async throws(StreamError) {
        try await write(bytes, byteCount: bytes.count)
    }

    public func write(_ string: String) async throws(StreamError) {
        try await write([UInt8](string.utf8))
    }
}

public protocol StreamWritable {
    func write(to stream: StreamWriter) async throws(StreamError)
}
