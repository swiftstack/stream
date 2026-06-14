public class BufferedStream<BaseStream: Stream>: Stream {
    public let inputStream: BufferedInputStream<BaseStream>
    public let outputStream: BufferedOutputStream<BaseStream>

    @inline(__always)
    public init(baseStream: BaseStream, capacity: Int = 4096) {
        inputStream = BufferedInputStream(
            baseStream: baseStream, capacity: capacity)
        outputStream = BufferedOutputStream(
            baseStream: baseStream, capacity: capacity)
    }

    @inline(__always)
    public func read(
        to buffer: UnsafeMutableRawPointer,
        byteCount: Int
    ) async throws -> Int {
        return try await inputStream.read(to: buffer, byteCount: byteCount)
    }

    @inline(__always)
    public func write(
        from buffer: UnsafeRawPointer,
        byteCount: Int
    ) async throws -> Int {
        return try await outputStream.write(from: buffer, byteCount: byteCount)
    }

    @inline(__always)
    public func flush() async throws {
        try await outputStream.flush()
    }
}
