extension BufferedInputStream: StreamReader {
    public func cache(count: Int) throws -> Bool {
        if count > buffered {
            try ensure(count: count)
            guard try feed() && buffered >= count else {
                return false
            }
        }
        return true
    }

    public func peek() throws -> UInt8 {
        guard try cache(count: 1) else {
            throw StreamError.insufficientData
        }
        return readPosition.assumingMemoryBound(to: UInt8.self).pointee
    }

    public func peek<T>(
        count: Int,
        body: (UnsafeRawBufferPointer) throws -> T) throws -> T
    {
        if count > buffered {
            try ensure(count: count)
            guard try feed() && buffered >= count else {
                throw StreamError.insufficientData
            }
        }
        let bytes = UnsafeRawBufferPointer(start: readPosition, count: count)
        return try body(bytes)
    }
}

extension BufferedInputStream {
    @inlinable // optimized
    public func read(_ type: UInt8.Type) throws -> UInt8 {
        if buffered == 0 {
            guard try feed() else {
                throw StreamError.insufficientData
            }
        }
        let byte = readPosition
            .assumingMemoryBound(to: UInt8.self)
            .pointee
        readPosition += 1
        return byte
    }

    @inlinable
    public func read<T: BinaryInteger>(_ type: T.Type) throws -> T {
        var result: T = 0
        try withUnsafeMutableBytes(of: &result) { pointer in
            return try read(count: MemoryLayout<T>.size) { bytes in
                pointer.copyMemory(from: bytes)
            }
        }
        return result
    }

    @inlinable
    public func read<T>(
        count: Int,
        body: (UnsafeRawBufferPointer) throws -> T) throws -> T
    {
        if count > buffered {
            if count > allocated {
                try ensure(count: count)
            } else {
                try ensure(count: count - buffered)
            }

            while buffered < count, try feed() {}

            guard count <= buffered else {
                throw StreamError.insufficientData
            }
        }
        let buffer = UnsafeRawBufferPointer(start: readPosition, count: count)
        readPosition += count
        return try body(buffer)
    }

    @inlinable
    public func read<T>(
        mode: PredicateMode,
        while predicate: (UInt8) -> Bool,
        body: (UnsafeRawBufferPointer) throws -> T) throws -> T
    {
        var read = 0
        while true {
            if read == buffered {
                try ensure(count: 1)
                guard try feed() else {
                    if mode == .untilEnd { break }
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

        let buffer = UnsafeRawBufferPointer(start: readPosition, count: read)
        readPosition += read
        return try body(buffer)
    }
}

extension BufferedInputStream {
    public func consume(count: Int) throws {
        guard buffered < count else {
            readPosition += count
            return
        }

        var rest = count - buffered
        clear()

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

    public func consume(_ byte: UInt8) throws -> Bool {
        if buffered == 0 {
            guard try feed() else {
                throw StreamError.insufficientData
            }
        }

        let next = readPosition
            .assumingMemoryBound(to: UInt8.self)
            .pointee

        guard next == byte else {
            return false
        }
        readPosition += 1
        return true
    }

    @inlinable
    public func consume(
        mode: PredicateMode,
        while predicate: (UInt8) -> Bool) throws
    {
        while true {
            if buffered == 0 {
                guard try feed() else {
                    if mode == .untilEnd { return }
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
    @usableFromInline
    func feed() throws -> Bool {
        guard used < allocated else {
            throw StreamError.notEnoughSpace
        }
        let read = try baseStream.read(
            to: writePosition,
            byteCount: allocated - used)
        guard read > 0 else {
            return false
        }
        writePosition += read
        return true
    }

    @usableFromInline
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
