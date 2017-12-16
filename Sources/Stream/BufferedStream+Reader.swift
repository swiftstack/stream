public protocol BufferedInputStreamReader {
    var count: Int { get }
    func peek(count: Int) -> UnsafeRawBufferPointer?
    func consume(count: Int) throws
    func consume(while predicate: (UInt8) -> Bool) throws -> Bool
    func read(count: Int) throws -> UnsafeRawBufferPointer
    func read(while predicate: (UInt8) -> Bool) throws -> UnsafeRawBufferPointer?
}

extension BufferedInputStreamReader {
    @inline(__always)
    public func read(until byte: UInt8) throws -> UnsafeRawBufferPointer? {
        return try read(while: {$0 != byte})
    }

    @inline(__always)
    @discardableResult
    public func consume(until byte: UInt8) throws -> Bool {
        return try consume(while: { $0 != byte })
    }
}

public enum BufferError: Error {
    case notEnoughSpace
    case insufficientData
}

extension BufferedInputStream: BufferedInputStreamReader {
    /// Get the next 'count' bytes (if present)
    /// without advancing current read position
    public func peek(count: Int) -> UnsafeRawBufferPointer? {
        guard count <= self.count else {
            return nil
        }
        return UnsafeRawBufferPointer(
            start: storage.advanced(by: readPosition),
            count: count)
    }

    @_versioned
    @inline(__always)
    func feed() throws -> Int {
        guard writePosition < allocated else {
            throw BufferError.notEnoughSpace
        }
        let read = try baseStream.read(
            to: storage.advanced(by: writePosition),
            byteCount: allocated - writePosition)
        writePosition += read
        return read
    }

    public func consume(count: Int) throws {
        _ = try read(count: count)
    }

    @inline(__always)
    @discardableResult
    public func consume(while predicate: (UInt8) -> Bool) throws -> Bool {
        try ensure(count: 1)
        while true {
            if self.count == 0 {
                guard try feed() > 0, self.count > 0 else {
                    return false
                }
            }
            let position = storage.advanced(by: readPosition)
                .assumingMemoryBound(to: UInt8.self)
            if !predicate(position.pointee) {
                return true
            }
            readPosition += 1
        }
    }

    public func read(count: Int) throws -> UnsafeRawBufferPointer {
        if count > self.count {
            if count > allocated {
                try ensure(count: count)
            } else {
                try ensure(count: count - self.count)
            }

            while self.count < count {
                if try feed() == 0 {
                    break
                }
            }

            guard count <= self.count else {
                throw BufferError.insufficientData
            }
        }
        defer {
            readPosition += count
        }
        return UnsafeRawBufferPointer(
            start: storage.advanced(by: readPosition),
            count: count)
    }

    @inline(__always)
    public func read(while predicate: (UInt8) -> Bool) throws -> UnsafeRawBufferPointer? {
        var count = 0
        while true {
            if readPosition + count == writePosition {
                try ensure(count: 1)
                guard try feed() > 0 else {
                    return nil
                }
            }
            let position = storage.advanced(by: readPosition + count)
                .assumingMemoryBound(to: UInt8.self)
            if !predicate(position.pointee) {
                break
            }
            count += 1
        }
        defer { readPosition += count }
        return UnsafeRawBufferPointer(
            start: storage.advanced(by: readPosition),
            count: count)
    }

    @_versioned
    func ensure(count requested: Int) throws {
        guard writePosition + requested > allocated else {
            return
        }

        switch expandable {
        case false:
            guard count + requested <= allocated else {
                throw BufferError.notEnoughSpace
            }
            shift()
        case true where count + requested <= allocated / 2:
            shift()
        default:
            reallocate(byteCount: (count + requested) * 2)
        }
    }

    func shift() {
        let count = self.count
        storage.copyMemory(
            from: storage.advanced(by: readPosition),
            byteCount: count)
        readPosition = 0
        writePosition = count
    }

    func reallocate(byteCount: Int) {
        let count = self.count
        let storage = UnsafeMutableRawPointer.allocate(
            byteCount: byteCount,
            alignment: MemoryLayout<UInt>.alignment)
        storage.copyMemory(
            from: self.storage.advanced(by: readPosition),
            byteCount: count)
        self.storage.deallocate()
        self.storage = storage
        self.allocated = byteCount
        self.readPosition = 0
        self.writePosition = count
    }
}
