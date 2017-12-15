public class BufferedInputStream<T: InputStream> {
    public let baseStream: T

    @_versioned
    var storage: UnsafeMutableRawBufferPointer
    var expandable: Bool

    public internal(set) var writePosition: Int = 0
    public internal(set) var readPosition: Int = 0 {
        @inline(__always) didSet {
            if readPosition > 0, readPosition == writePosition {
                readPosition = 0
                writePosition = 0
            }
        }
    }

    public var count: Int {
        @inline(__always) get {
            return writePosition - readPosition
        }
    }

    public var capacity: Int {
        @inline(__always) get {
            return storage.count
        }
    }

    public init(baseStream: T, capacity: Int = 0, expandable: Bool = true) {
        let storage = capacity == 0
            ? UnsafeMutableRawBufferPointer(start: nil, count: 0)
            : UnsafeMutableRawBufferPointer.allocate(
                byteCount: capacity,
                alignment: MemoryLayout<UInt>.alignment)

        self.baseStream = baseStream
        self.storage = storage
        self.expandable = expandable
    }

    deinit {
        storage.deallocate()
    }
}

extension BufferedInputStream: InputStream {
    private func read(
    _ count: Int
    ) -> UnsafeMutableRawBufferPointer.SubSequence {
        let slice = storage[readPosition..<readPosition+count]
        readPosition += count
        return slice
    }

    public func read(to buffer: UnsafeMutableRawBufferPointer) throws -> Int {
        switch self.count - buffer.count {

        // we have buffered more than requested
        case 0...:
            buffer.copyBytes(from: read(buffer.count))
            return buffer.count

        // we don't have enough data and can buffer the rest after read
        case -(storage.count-1)..<0:
            let flushed = flush(to: buffer)
            writePosition = try baseStream.read(to: storage)
            let remain = min(count, buffer.count - flushed)
            UnsafeMutableRawBufferPointer(rebasing: buffer[flushed...])
                .copyBytes(from: read(remain))
            return flushed + remain

        // requested more than we can buffer, read directly into the buffer
        default:
            guard self.count > 0 else {
                return try baseStream.read(to: buffer)
            }
            let flushed = flush(to: buffer)
            let read = try baseStream.read(
                to: UnsafeMutableRawBufferPointer(
                    rebasing: buffer[flushed...]))
            return flushed + read
        }
    }

    @inline(__always)
    private func flush(to buffer: UnsafeMutableRawBufferPointer) -> Int {
        assert(buffer.count > self.count)
        buffer.copyBytes(from: storage[readPosition..<writePosition])
        let flushed = count
        readPosition = 0
        writePosition = 0
        return flushed
    }
}

public class BufferedOutputStream<T: OutputStream> {
    public let baseStream: T

    let storage: UnsafeMutableRawBufferPointer
    var buffered: Int

    var available: Int {
        return storage.count - buffered
    }

    public init(baseStream: T, capacity: Int = 4096) {
        self.baseStream = baseStream
        storage = UnsafeMutableRawBufferPointer.allocate(
            byteCount: capacity,
            alignment: MemoryLayout<UInt>.alignment)
        buffered = 0
    }

    deinit {
        storage.deallocate()
    }
}

extension BufferedOutputStream: OutputStream {
    public func write(_ bytes: UnsafeRawBufferPointer) throws -> Int {
        switch available - bytes.count {
        // the bytes fit into the buffer
        case 0...:
            UnsafeMutableRawBufferPointer(rebasing: storage[buffered...])
                .copyMemory(from: bytes)
            buffered += bytes.count
            if buffered == storage.count {
                try flush()
            }
            return bytes.count

        // the buffer is full, copy as much as we can, flush, buffer the rest
        case -(storage.count-1)..<0:
            let count = available
            UnsafeMutableRawBufferPointer(rebasing: storage[buffered...])
                .copyBytes(from: bytes[..<count])
            buffered += count
            try flush()
            storage.copyBytes(from: bytes[count...])
            buffered += bytes.count - count
            return bytes.count

        // we can't buffer the bytes, pass it directly into baseStream
        default:
            if buffered > 0 {
                try flush()
            }
            return try baseStream.write(bytes)
        }
    }

    @discardableResult
    public func flush() throws -> Int {
        var sent = 0
        while sent < buffered {
            sent += try baseStream.write(
                UnsafeRawBufferPointer(rebasing: storage[sent..<buffered]))
        }
        buffered = 0
        return sent
    }
}

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
    public func read(to buffer: UnsafeMutableRawBufferPointer) throws -> Int {
        return try inputStream.read(to: buffer)
    }

    @inline(__always)
    public func write(_ bytes: UnsafeRawBufferPointer) throws -> Int {
        return try outputStream.write(bytes)
    }

    @inline(__always)
    public func flush() throws {
        try outputStream.flush()
    }
}
