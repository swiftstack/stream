public protocol BufferedInputStreamReader {
    var count: Int { get }
    func peek(count: Int) -> UnsafeRawBufferPointer.SubSequence?
    func consume(count: Int) throws
    func consume(while predicate: (UInt8) -> Bool) throws -> Bool
    func read(count: Int) throws -> UnsafeRawBufferPointer.SubSequence
    func read(while predicate: (UInt8) -> Bool) throws -> UnsafeRawBufferPointer.SubSequence?
}

extension BufferedInputStreamReader {
    @inline(__always)
    public func read(until byte: UInt8) throws -> UnsafeRawBufferPointer.SubSequence? {
        return try read(while: {$0 != byte})
    }

    @inline(__always)
    @discardableResult
    public func consume(until byte: UInt8) throws -> Bool {
        return try consume(while: {$0 != byte})
    }
}

public enum BufferError: Error {
    case notEnoughSpace
    case insufficientData
}

extension BufferedInputStream: BufferedInputStreamReader {
    /// Get the next 'count' bytes (if present)
    /// without advancing current read position
    public func peek(count: Int) -> UnsafeRawBufferPointer.SubSequence? {
        guard count <= self.count else {
            return nil
        }
        return UnsafeRawBufferPointer(storage)[readPosition..<readPosition+count]
    }

    @_versioned
    @inline(__always)
    func feed() throws -> Int {
        guard writePosition < capacity else {
            throw BufferError.notEnoughSpace
        }
        let buffer = storage[writePosition...]
        let rebased = UnsafeMutableRawBufferPointer(rebasing: buffer)
        let read = try baseStream.read(to: rebased)
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
            if !predicate(storage[readPosition]) {
                return true
            }
            readPosition += 1
        }
    }

    public func read(count: Int) throws -> UnsafeRawBufferPointer.SubSequence {
        if count > self.count {
            if count > capacity {
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
        return UnsafeRawBufferPointer(storage)[readPosition..<readPosition+count]
    }

    @inline(__always)
    public func read(while predicate: (UInt8) -> Bool) throws -> UnsafeRawBufferPointer.SubSequence? {
        var count = 0
        while true {
            if readPosition + count == writePosition {
                try ensure(count: 1)
                guard try feed() > 0 else {
                    return nil
                }
            }
            if !predicate(storage[readPosition + count]) {
                break
            }
            count += 1
        }
        defer { readPosition += count }
        return UnsafeRawBufferPointer(storage)[readPosition..<readPosition+count]
    }

    @_versioned
    func ensure(count requested: Int) throws {
        guard writePosition + requested > capacity else {
            return
        }

        switch expandable {
        case false:
            guard count + requested <= capacity else {
                throw BufferError.notEnoughSpace
            }
            shift()
        case true where count + requested <= capacity / 2:
            shift()
        default:
            reallocate(byteCount: (count + requested) * 2)
        }
    }

    func shift() {
        let count = self.count
        storage.copyBytes(from: storage[readPosition..<writePosition])
        readPosition = 0
        writePosition = count
    }

    func reallocate(byteCount: Int) {
        let count = self.count
        let storage = UnsafeMutableRawBufferPointer.allocate(
            byteCount: byteCount,
            alignment: MemoryLayout<UInt>.alignment)
        storage.copyBytes(from: self.storage[readPosition..<writePosition])
        self.storage.deallocate()
        self.storage = storage
        self.readPosition = 0
        self.writePosition = count
    }
}
