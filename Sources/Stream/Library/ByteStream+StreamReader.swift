// Convenience conformance

extension InputByteStream: StreamReader {
    public var buffered: Int {
        return bytes.count - position
    }

    @inline(__always)
    func ensure(count: Int) throws {
        guard buffered >= count else {
            throw StreamError.insufficientData
        }
    }

    @inline(__always)
    func advance(by count: Int) {
        position += count
    }

    public func peek() throws -> UInt8 {
        try ensure(count: 1)
        return bytes[position]
    }

    public func peek<T>(
        count: Int,
        body: (UnsafeRawBufferPointer) throws -> T) throws -> T
    {
        try ensure(count: count)
        return try bytes[position..<position+count].withUnsafeBytes(body)
    }

    public func read(_ type: UInt8.Type) throws -> UInt8 {
        try ensure(count: 1)
        defer { advance(by: 1) }
        return bytes[position]
    }

    public func read<T: BinaryInteger>(_ type: T.Type) throws -> T {
        let count = MemoryLayout<T>.size
        try ensure(count: count)
        defer { advance(by: count) }
        var result: T = 0
        bytes[position..<position+count].withUnsafeBytes { bytes in
            withUnsafeMutableBytes(of: &result) { buffer in
                buffer.copyMemory(from: bytes)
            }
        }
        return result
    }

    public func read<T>(
        count: Int,
        body: (UnsafeRawBufferPointer) throws -> T) throws -> T
    {
        try ensure(count: count)
        defer { advance(by: count) }
        let slice = bytes[position..<position+count]
        return try slice.withUnsafeBytes { bytes in
            return try body(bytes)
        }
    }

    public func read<T>(
        while predicate: (UInt8) -> Bool,
        untilEnd: Bool,
        body: (UnsafeRawBufferPointer) throws -> T) throws -> T
    {
        var read = 0
        defer { advance(by: read) }
        while true {
            if read == buffered {
                if untilEnd { break }
                throw StreamError.insufficientData
            }
            if !predicate(bytes[position+read]) {
                break
            }
            read += 1
        }
        let slice = bytes[position..<(position+read)]
        return try slice.withUnsafeBytes { bytes in
            return try body(bytes)
        }
    }

    public func consume(count: Int) throws {
        try ensure(count: count)
        advance(by: count)
    }

    public func consume(_ byte: UInt8) throws -> Bool {
        try ensure(count: 1)
        guard bytes[position] == byte else {
            return false
        }
        advance(by: 1)
        return true
    }

    public func consume(
        while predicate: (UInt8) -> Bool,
        untilEnd: Bool) throws
    {
        while true {
            if position == bytes.count {
                if untilEnd { break }
                throw StreamError.insufficientData
            }
            if !predicate(bytes[position]) {
                break
            }
            advance(by: 1)
        }
    }

    public func cache(count: Int) throws -> Bool {
        do {
            try ensure(count: count)
            return true
        } catch {
            return false
        }
    }
}
