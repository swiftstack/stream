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
        try? flush()
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

    public func flush() throws {
        var sent = 0
        while sent < buffered {
            sent += try baseStream.write(
                from: storage.advanced(by: sent),
                byteCount: buffered - sent)
        }
        buffered = 0
    }
}
