public class BufferedInputStream<T: InputStream>: InputStream {
    public let baseStream: T

    let storage: UnsafeMutableRawBufferPointer
    var position: Int
    var count: Int

    var buffered: Int {
        return count - position
    }

    public init(stream: T, capacity: Int = 4096) {
        self.baseStream = stream
        self.storage = UnsafeMutableRawBufferPointer.allocate(
            byteCount: capacity,
            alignment: MemoryLayout<UInt>.alignment)
        self.position = 0
        self.count = 0
    }

    deinit {
        storage.deallocate()
    }

    @inline(__always)
    private func flush(to buffer: UnsafeMutableRawBufferPointer) -> Int {
        assert(buffer.count > buffered)
        buffer.copyBytes(from: storage[position..<count])
        let flushed = buffered
        position = 0
        count = 0
        return flushed
    }

    @inline(__always)
    private func read(count: Int) -> UnsafeMutableRawBufferPointer.SubSequence {
        assert(buffered >= count)
        position += count
        return storage[position-count..<position]
    }

    public func read(to buffer: UnsafeMutableRawBufferPointer) throws -> Int {
        switch buffered - buffer.count {
        case 0...:
            buffer.copyBytes(from: read(count: buffer.count))
            return buffer.count
        // we don't have enough data and can buffer the rest after read
        case -(storage.count-1)..<0:
            let flushed = flush(to: buffer)
            count = try baseStream.read(to: storage)
            let remain = min(count, buffer.count - flushed)
            UnsafeMutableRawBufferPointer(rebasing: buffer[flushed...])
                .copyBytes(from: read(count: remain))
            return flushed + remain
        // requested more than we can buffer, read directly to the buffer
        default:
            switch buffered {
            case 0: // fast path if we always read more than capacity
                return try baseStream.read(to: buffer)
            default:
                let flushed = flush(to: buffer)
                let read = try baseStream.read(
                    to: UnsafeMutableRawBufferPointer(
                        rebasing: buffer[flushed...]))
                return flushed + read
            }
        }
    }
}

public class BufferedOutputStream<T: OutputStream>: OutputStream {
    public let baseStream: T

    let storage: UnsafeMutableRawBufferPointer
    var buffered: Int

    var available: Int {
        return storage.count - buffered
    }

    public init(stream: T, capacity: Int = 4096) {
        baseStream = stream
        storage = UnsafeMutableRawBufferPointer.allocate(
            byteCount: capacity,
            alignment: MemoryLayout<UInt>.alignment)
        buffered = 0
    }

    deinit {
        storage.deallocate()
    }

    public func write(_ bytes: UnsafeRawBufferPointer) throws -> Int {
        switch available - bytes.count {
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
        default:
            var sent = 0
            if buffered > 0 {
                try flush()
            }
            sent += try baseStream.write(bytes)
            return sent
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
    public init(stream: T, capacity: Int = 4096) {
        inputStream = BufferedInputStream(stream: stream, capacity: capacity)
        outputStream = BufferedOutputStream(stream: stream, capacity: capacity)
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
