public class BufferedStream<T: Stream>: Stream {
    public let inputStream: BufferedInputStream<T>
    public let outputStream: BufferedOutputStream<T>

    @inline(__always)
    public init(baseStream: T, capacity: Int = 4096) {
        inputStream = BufferedInputStream(
            baseStream: baseStream, capacity: capacity)
        outputStream = BufferedOutputStream(
            baseStream: baseStream, capacity: capacity)
    }

    @inline(__always)
    public func read(
        to buffer: UnsafeMutableRawPointer,
        byteCount: Int) throws -> Int {
        return try inputStream.read(to: buffer, byteCount: byteCount)
    }

    @inline(__always)
    public func write(
        from buffer: UnsafeRawPointer,
        byteCount: Int) throws -> Int
    {
        return try outputStream.write(from: buffer, byteCount: byteCount)
    }

    @inline(__always)
    public func flush() throws {
        try outputStream.flush()
    }
}

extension BufferedStream: StreamReader {
    public func cache(count: Int) throws -> Bool {
        return try inputStream.cache(count: count)
    }

    public func peek() throws -> UInt8 {
        return try inputStream.peek()
    }

    public func peek<T>(
        count: Int,
        body: (UnsafeRawBufferPointer) throws -> T) throws -> T
    {
        return try inputStream.peek(count: count, body: body)
    }

    public func read<T: FixedWidthInteger>(_ type: T.Type) throws -> T {
        return try inputStream.read(type)
    }

    public func read<T>(
        count: Int,
        body: (UnsafeRawBufferPointer) throws -> T) throws -> T
    {
        return try inputStream.read(count: count, body: body)
    }

    public func read<T>(
        mode: PredicateMode,
        while predicate: (UInt8) -> Bool,
        body: (UnsafeRawBufferPointer) throws -> T) throws -> T
    {
        return try inputStream.read(mode: mode, while: predicate, body: body)
    }

    public func consume(count: Int) throws {
        return try inputStream.consume(count: count)
    }

    public func consume(_ byte: UInt8) throws -> Bool {
        return try inputStream.consume(byte)
    }

    public func consume(mode: PredicateMode, while predicate: (UInt8) -> Bool) throws
    {
        try inputStream.consume(mode: mode, while: predicate)
    }
}

extension BufferedStream: StreamWriter {
    public func write(_ byte: UInt8) throws {
        try outputStream.write(byte)
    }

    public func write<T: FixedWidthInteger>(_ value: T) throws {
        try outputStream.write(value)
    }

    public func write(_ bytes: UnsafeRawPointer, byteCount: Int) throws {
        try outputStream.write(bytes, byteCount: byteCount)
    }
}
