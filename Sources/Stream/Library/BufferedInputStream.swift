public class BufferedInputStream<T: InputStream> {
    public let baseStream: T

    @_versioned
    var storage: UnsafeMutableRawPointer
    public internal(set) var allocated: Int

    var expandable: Bool

    // FIXME: internal(set) + mutating from @_inlineable = crash
    public public(set) var writePosition: UnsafeMutableRawPointer
    public public(set) var readPosition: UnsafeMutableRawPointer {
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

    public func clear() {
        readPosition = storage
        writePosition = storage
    }
}

extension BufferedInputStream: InputStream {
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
    private func read(_ count: Int) -> UnsafeMutableRawPointer {
        let pointer = readPosition
        readPosition += count
        return pointer
    }

    @inline(__always)
    private func flush(
        to buffer: UnsafeMutableRawPointer,
        byteCount: Int) -> Int
    {
        assert(byteCount > buffered)
        buffer.copyMemory(from: readPosition, byteCount: buffered)
        let flushed = buffered
        clear()
        return flushed
    }
}
