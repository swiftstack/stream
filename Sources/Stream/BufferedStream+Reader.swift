extension BufferedInputStream {
    @inline(__always)
    public func read(until byte: UInt8) throws -> UnsafeRawBufferPointer {
        return try read(while: { $0 != byte }, untilEnd: false)
    }

    @inline(__always)
    public func consume(until byte: UInt8) throws {
        _ = try consume(while: { $0 != byte }, untilEnd: false)
    }
}

extension BufferedInputStream {
    /// Get the next 'count' bytes (if present)
    /// without advancing current read position
    @_inlineable
    public func peek(count: Int) throws -> UnsafeRawBufferPointer? {
        if count > buffered {
            try ensure(count: count)
            guard try feed() > 0 && buffered >= count else {
                return nil
            }
        }
        return UnsafeRawBufferPointer(start: readPosition, count: count)
    }
}

extension BufferedInputStream {
    public func read(count: Int) throws -> UnsafeRawBufferPointer {
        if count > buffered {
            if count > allocated {
                try ensure(count: count)
            } else {
                try ensure(count: count - buffered)
            }

            while buffered < count {
                if try feed() == 0 {
                    break
                }
            }

            guard count <= buffered else {
                throw StreamError.insufficientData
            }
        }
        defer { readPosition += count }
        return UnsafeRawBufferPointer(start: readPosition, count: count)
    }

    @_inlineable
    public func read(
        while predicate: (UInt8) -> Bool,
        untilEnd: Bool = true
    ) throws -> UnsafeRawBufferPointer {
        var read = 0
        while true {
            if read == buffered {
                try ensure(count: 1)
                guard try feed() > 0 else {
                    if untilEnd { break }
                    throw StreamError.insufficientData
                }
            }
            let byte = readPosition
                .advanced(by: read)
                .assumingMemoryBound(to: UInt8.self)
                .pointee
            if !predicate(byte) {
                break
            }
            read += 1
        }
        defer { readPosition += read }
        return UnsafeRawBufferPointer(start: readPosition, count: read)
    }
}

extension BufferedInputStream {
    public func consume(count: Int) throws {
        guard buffered < count else {
            readPosition += count
            return
        }

        var rest = count - buffered
        reset()

        if rest > allocated && expandable {
            reallocate(byteCount: rest)
        }

        var read = 0
        while rest > 0 {
            read = try baseStream.read(to: storage, byteCount: allocated)
            rest -= read
        }
        readPosition = storage + (-rest)
        writePosition = storage + read
    }

    @_inlineable
    public func consume(
        while predicate: (UInt8) -> Bool,
        untilEnd: Bool = true
    ) throws {
        try ensure(count: 1)
        while true {
            if buffered == 0 {
                guard try feed() > 0 else {
                    if untilEnd { return }
                    throw StreamError.insufficientData
                }
            }
            let byte = readPosition.assumingMemoryBound(to: UInt8.self)
            if !predicate(byte.pointee) {
                return
            }
            readPosition += 1
        }
    }
}

extension BufferedInputStream {
    @_versioned
    func feed() throws -> Int {
        guard used < allocated else {
            throw StreamError.notEnoughSpace
        }
        let read = try baseStream.read(
            to: writePosition,
            byteCount: allocated - used)
        writePosition += read
        return read
    }

    @_versioned
    func ensure(count requested: Int) throws {
        guard used + requested > allocated else {
            return
        }

        switch expandable {
        case false:
            guard buffered + requested <= allocated else {
                throw StreamError.notEnoughSpace
            }
            shift()
        case true where buffered + requested <= allocated / 2:
            shift()
        default:
            reallocate(byteCount: (buffered + requested) * 2)
        }
    }

    func shift() {
        let count = buffered
        storage.copyMemory(from: readPosition, byteCount: count)
        readPosition = storage
        writePosition = storage + count
    }

    func reallocate(byteCount: Int) {
        let count = buffered
        let storage = UnsafeMutableRawPointer.allocate(
            byteCount: byteCount,
            alignment: MemoryLayout<UInt>.alignment)
        storage.copyMemory(from: self.readPosition, byteCount: count)
        self.storage.deallocate()
        self.storage = storage
        self.allocated = byteCount
        self.readPosition = storage
        self.writePosition = storage + count
    }
}
