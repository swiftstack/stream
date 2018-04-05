public class InputByteStream: InputStream {
    public let bytes: [UInt8]

    public internal(set) var position = 0

    public var isEmpty: Bool {
        return position == bytes.count
    }

    public init(_ bytes: [UInt8]) {
        self.bytes = bytes
    }

    @inline(__always)
    public func read(
        to pointer: UnsafeMutableRawPointer,
        byteCount: Int) throws -> Int
    {
        let count = min(bytes.count - position, byteCount)
        let source = UnsafeRawPointer(bytes).advanced(by: position)
        pointer.copyMemory(from: source, byteCount: count)
        position += count
        return count
    }
}

public class OutputByteStream: OutputStream {
    public var bytes: [UInt8]

    public var position: Int {
        return bytes.count
    }

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

public class ByteStream: Stream {
    public let inputStream: InputByteStream
    public let outputStream: OutputByteStream

    public init(inputStream: InputByteStream, outputStream: OutputByteStream) {
        self.inputStream = inputStream
        self.outputStream = outputStream
    }

    public func read(
        to pointer: UnsafeMutableRawPointer,
        byteCount: Int) throws -> Int
    {
        return try inputStream.read(to: pointer, byteCount: byteCount)
    }

    public func write(
        from buffer: UnsafeRawPointer,
        byteCount: Int) throws -> Int
    {
        return try outputStream.write(from: buffer, byteCount: byteCount)
    }
}
