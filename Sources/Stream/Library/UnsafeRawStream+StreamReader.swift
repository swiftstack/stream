// Convenience conformance

extension UnsafeRawInputStream: StreamReader {
    var bytes: UnsafeRawBufferPointer {
        @inline(__always) get {
            return UnsafeRawBufferPointer(start: pointer, count: count)
        }
    }

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
        let slice = bytes[position..<position+count]
        return try body(UnsafeRawBufferPointer(rebasing: slice))
    }

    public func read(_ type: UInt8.Type) throws -> UInt8 {
        try ensure(count: 1)
        advance(by: 1)
        return bytes[position-1]
    }

    public func read<T: FixedWidthInteger>(_ type: T.Type) throws -> T {
        let count = MemoryLayout<T>.size
        try ensure(count: count)
        var result: T = 0
        let slice = bytes[position..<position+count]
        advance(by: count)
        withUnsafeMutableBytes(of: &result) { buffer in
            buffer.copyMemory(from: UnsafeRawBufferPointer(rebasing: slice))
        }
        return result.bigEndian
    }

    public func read<T>(
        count: Int,
        body: (UnsafeRawBufferPointer) throws -> T) throws -> T
    {
        try ensure(count: count)
        let slice = self.bytes[position..<position+count]
        advance(by: count)
        let bytes = UnsafeRawBufferPointer(rebasing: slice)
        return try body(bytes)
    }

    public func read<T>(
        mode: PredicateMode,
        while predicate: (UInt8) -> Bool,
        body: (UnsafeRawBufferPointer) throws -> T) throws -> T
    {
        var read = 0
        while true {
            if read == buffered {
                if mode == .untilEnd { break }
                throw StreamError.insufficientData
            }
            if !predicate(bytes[position+read]) {
                break
            }
            read += 1
        }
        let slice = self.bytes[position..<(position+read)]
        advance(by: read)
        return try body(UnsafeRawBufferPointer(rebasing: slice))
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
        mode: PredicateMode,
        while predicate: (UInt8) -> Bool) throws
    {
        while true {
            if position == bytes.count {
                if mode == .untilEnd { break }
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
