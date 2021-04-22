public class ByteArrayOutputStream: OutputStream {
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
        byteCount: Int) -> Int
    {
        bytes.append(contentsOf: UnsafeRawBufferPointer(
            start: buffer,
            count: byteCount))
        return byteCount
    }
}

@available(*, renamed: "ByteArrayOutputStream")
public typealias OutputByteStream = ByteArrayOutputStream
