public class BufferedInputStream<T: InputStream> {
    public let baseStream: T

    @_versioned
    var storage: UnsafeMutableRawPointer
    public internal(set) var allocated: Int

    var expandable: Bool

    public internal(set) var writePosition: UnsafeMutableRawPointer
    public internal(set) var readPosition: UnsafeMutableRawPointer {
        @inline(__always) didSet {
            if readPosition == writePosition {
                readPosition = storage
                writePosition = storage
            }
        }
    }

    public var buffered: Int {
        @inline(__always) get {
            return readPosition.distance(to: writePosition)
        }
    }

    public var used: Int {
        @inline(__always) get {
            return storage.distance(to: writePosition)
        }
    }

    public init(baseStream: T, capacity: Int = 256, expandable: Bool = true) {
        guard capacity > 0 else {
            fatalError("capacity must be > 0")
        }
        self.baseStream = baseStream
        self.storage = UnsafeMutableRawPointer.allocate(
            byteCount: capacity,
            alignment: MemoryLayout<UInt>.alignment)
        self.allocated = capacity
        self.expandable = expandable

        self.readPosition = storage
        self.writePosition = storage
    }

    deinit {
        storage.deallocate()
    }
}

extension BufferedInputStream: InputStream {
    @inline(__always)
    private func read(_ count: Int) -> UnsafeMutableRawPointer {
        let pointer = readPosition
        readPosition += count
        return pointer
    }

    public func read(
        to buffer: UnsafeMutableRawPointer, byteCount: Int
    ) throws -> Int {
        switch buffered - byteCount {

        // we have buffered more than requested
        case 0...:
            buffer.copyMemory(from: read(byteCount), byteCount: byteCount)
            return byteCount

        // we don't have enough data and can buffer the rest after read
        case -(allocated-1)..<0:
            let flushed = flush(to: buffer, byteCount: byteCount)
            let bytesRead = try baseStream.read(to: storage, byteCount: allocated)
            writePosition = self.storage + bytesRead
            let remain = min(buffered, byteCount - flushed)
            buffer.advanced(by: flushed)
                .copyMemory(from: read(remain), byteCount: remain)
            return flushed + remain

        // requested more than we can buffer, read directly into the buffer
        default:
            guard buffered > 0 else {
                return try baseStream.read(to: buffer, byteCount: byteCount)
            }
            let flushed = flush(to: buffer, byteCount: byteCount)
            let read = try baseStream.read(
                to: buffer.advanced(by: flushed),
                byteCount: byteCount - flushed)
            return flushed + read
        }
    }

    @inline(__always)
    private func flush(
        to buffer: UnsafeMutableRawPointer, byteCount: Int
    ) -> Int {
        assert(byteCount > buffered)
        buffer.copyMemory(from: readPosition, byteCount: buffered)
        let flushed = buffered
        reset()
        return flushed
    }

    @inline(__always)
    func reset() {
        readPosition = storage
        writePosition = storage
    }
}

public class BufferedOutputStream<T: OutputStream> {
    public let baseStream: T

    let storage: UnsafeMutableRawPointer
    let allocated: Int

    public internal(set) var buffered: Int

    var available: Int {
        return allocated - buffered
    }

    public init(baseStream: T, capacity: Int = 256) {
        guard capacity > 0 else {
            fatalError("capacity must be > 0")
        }
        self.baseStream = baseStream
        self.storage = UnsafeMutableRawPointer.allocate(
            byteCount: capacity,
            alignment: MemoryLayout<UInt>.alignment)
        self.allocated = capacity
        self.buffered = 0
    }

    deinit {
        storage.deallocate()
    }
}

extension BufferedOutputStream: OutputStream {
    public func write(
        from buffer: UnsafeRawPointer,
        byteCount: Int) throws -> Int
    {
        switch available - byteCount {
        // the bytes fit into the buffer
        case 0...:
            storage.advanced(by: buffered)
                .copyMemory(from: buffer, byteCount: byteCount)
            buffered += byteCount
            if buffered == allocated {
                try flush()
            }
            return byteCount

        // the buffer is full, copy as much as we can, flush, buffer the rest
        case -(allocated-1)..<0:
            let count = available
            storage.advanced(by: buffered)
                .copyMemory(from: buffer, byteCount: count)
            buffered += count
            try flush()
            let rest = buffer.advanced(by: count)
            storage.copyMemory(from: rest, byteCount: byteCount - count)
            buffered += byteCount - count
            return byteCount

        // we can't buffer the bytes, pass it directly into baseStream
        default:
            if buffered > 0 {
                try flush()
            }
            return try baseStream.write(from: buffer, byteCount: byteCount)
        }
    }

    @discardableResult
    public func flush() throws -> Int {
        var sent = 0
        while sent < buffered {
            sent += try baseStream.write(
                from: storage.advanced(by: sent),
                byteCount: buffered - sent)
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
