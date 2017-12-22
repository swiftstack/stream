// Convenience conformance

extension InputByteStream: UnsafeStreamReader {
    public var buffered: Int {
        return bytes.count - position
    }

    private var buffer: UnsafeRawBufferPointer {
        return UnsafeRawBufferPointer(start: bytes, count: bytes.count)
    }

    func ensure(count: Int) throws {
        guard buffered >= count else {
            throw StreamError.insufficientData
        }
    }

    public func peek(count: Int) throws -> UnsafeRawBufferPointer? {
        do {
            try ensure(count: count)
        } catch {
            return nil
        }
        let result = buffer[position..<position+count]
        return UnsafeRawBufferPointer(rebasing: result)
    }

    public func read() throws -> UInt8 {
        try ensure(count: 1)
        defer { position += 1 }
        return buffer[position]
    }

    public func read(count: Int) throws -> UnsafeRawBufferPointer {
        try ensure(count: count)
        defer { position += count }
        let result = buffer[position..<position+count]
        return UnsafeRawBufferPointer(rebasing: result)
    }

    public func read(
        while predicate: (UInt8) -> Bool,
        allowingExhaustion: Bool
    ) throws -> UnsafeRawBufferPointer {
        var read = 0
        defer { position += read }
        while true {
            if read == buffered {
                if allowingExhaustion { break }
                throw StreamError.insufficientData
            }
            if !predicate(buffer[position+read]) {
                break
            }
            read += 1
        }
        let result = buffer[position..<(position+read)]
        return UnsafeRawBufferPointer(rebasing: result)
    }

    public func consume(count: Int) throws {
        try ensure(count: count)
        position += count
    }

    public func consume(_ byte: UInt8) throws -> Bool {
        try ensure(count: 1)
        guard buffer[position] == byte else {
            return false
        }
        position += 1
        return true
    }

    public func consume(
        while predicate: (UInt8) -> Bool,
        allowingExhaustion: Bool
    ) throws {
        while true {
            if position == bytes.count {
                if allowingExhaustion { break }
                throw StreamError.insufficientData
            }
            if !predicate(buffer[position]) {
                break
            }
            position += 1
        }
    }
}
