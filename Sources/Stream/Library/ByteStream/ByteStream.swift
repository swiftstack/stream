public class InputByteStream: InputStream {
    public let bytes: [UInt8]
    public internal(set) var position = 0
    public var isEmpty: Bool { position == bytes.count }

    public init(_ bytes: [UInt8]) {
        self.bytes = bytes
    }

    convenience public init(_ string: String) {
        self.init([UInt8](string.utf8))
    }

    @inline(__always)
    public func read(
        to pointer: UnsafeMutableRawPointer,
        byteCount: Int) throws -> Int
    {
        let count = min(bytes.count - position, byteCount)
        let buffer = UnsafeMutableRawBufferPointer(start: pointer, count: count)
        buffer.copyBytes(from: bytes[position..<position + count])
        position += count
        return count
    }
}

public class OutputByteStream: OutputStream {
    public var bytes: [UInt8]
    public var position: Int { bytes.count }
    public var stringValue: String { .init(decoding: bytes, as: UTF8.self) }

    public init(reservingCapacity capacity: Int = 256) {
        bytes = []
        bytes.reserveCapacity(capacity)
    }

    @inline(__always)
    public func write(
        from buffer: UnsafeRawPointer,
        byteCount: Int) throws -> Int
    {
        bytes.append(contentsOf: UnsafeRawBufferPointer(
            start: buffer,
            count: byteCount))
        return byteCount
    }
}
