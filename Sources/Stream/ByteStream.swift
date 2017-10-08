public struct InputByteStream: InputStream {
    public let bytes: [UInt8]

    public var position = 0

    public init(_ bytes: [UInt8]) {
        self.bytes = bytes
    }

    @inline(__always)
    public mutating func read(
        to buffer: UnsafeMutableRawBufferPointer
    ) throws -> Int {
        let count = min(bytes.count - position, buffer.count)
        buffer.copyBytes(from: bytes[position..<position+count])
        position += count
        return count
    }
}

public struct OutputByteStream: OutputStream {
    public var bytes: [UInt8]

    public init(reservingCapacity capacity: Int = 1024) {
        bytes = []
        bytes.reserveCapacity(capacity)
    }

    @inline(__always)
    public mutating func write(_ bytes: UnsafeRawBufferPointer) throws -> Int {
        self.bytes.append(contentsOf: bytes)
        return bytes.count
    }
}
