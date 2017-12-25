public class InputByteStream: InputStream {
    public let bytes: [UInt8]

    public internal(set) var position = 0

    public init(_ bytes: [UInt8]) {
        self.bytes = bytes
    }

    @inline(__always)
    public func read(
        to pointer: UnsafeMutableRawPointer,
        byteCount: Int
    ) throws -> Int {
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
    public func write(_ bytes: UnsafeRawPointer, byteCount: Int) throws -> Int {
        let buffer = UnsafeRawBufferPointer(start: bytes, count: byteCount)
        self.bytes.append(contentsOf: buffer)
        return byteCount
    }
}

public class ByteStream {
    public let inputStream: InputByteStream
    public let outputStream: OutputByteStream

    init(inputStream: InputByteStream, outputStream: OutputByteStream) {
        self.inputStream = inputStream
        self.outputStream = outputStream
    }

    func read(
        to pointer: UnsafeMutableRawPointer,
        byteCount: Int
    ) throws -> Int {
        return try inputStream.read(to: pointer, byteCount: byteCount)
    }

    func write(_ bytes: UnsafeRawPointer, byteCount: Int) throws -> Int {
        return try outputStream.write(bytes, byteCount: byteCount)
    }
}
