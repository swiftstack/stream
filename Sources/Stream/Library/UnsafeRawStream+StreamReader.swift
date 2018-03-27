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
        let slice = bytes[position..<position+count]
        withUnsafeMutableBytes(of: &result) { buffer in
            buffer.copyMemory(from: UnsafeRawBufferPointer(rebasing: slice))
        }
        return result
    }

    private func _read(count: Int) throws -> Slice<UnsafeRawBufferPointer> {
        try ensure(count: count)
        defer { advance(by: count) }
        return bytes[position..<position+count]
    }

    public func read(count: Int) throws -> [UInt8] {
        return [UInt8](try _read(count: count))
    }

    public func read<T>(
        count: Int,
        body: (UnsafeRawBufferPointer) throws -> T) throws -> T
    {
        let bytes = UnsafeRawBufferPointer(rebasing: try _read(count: count))
        return try body(bytes)
    }

    private func _read(
        while predicate: (UInt8) -> Bool,
        allowingExhaustion: Bool) throws -> Slice<UnsafeRawBufferPointer>
    {
        var read = 0
        defer { advance(by: read) }
        while true {
            if read == buffered {
                if allowingExhaustion { break }
                throw StreamError.insufficientData
            }
            if !predicate(bytes[position+read]) {
                break
            }
            read += 1
        }
        return bytes[position..<(position+read)]
    }

    public func read(
        while predicate: (UInt8) -> Bool,
        allowingExhaustion: Bool) throws -> [UInt8]
    {
        let slice = try _read(
            while: predicate,
            allowingExhaustion: allowingExhaustion)
        return [UInt8](slice)
    }

    public func read<T>(
        while predicate: (UInt8) -> Bool,
        allowingExhaustion: Bool,
        body: (UnsafeRawBufferPointer) throws -> T) throws -> T
    {
        let slice = try _read(
            while: predicate,
            allowingExhaustion: allowingExhaustion)
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
        while predicate: (UInt8) -> Bool,
        allowingExhaustion: Bool) throws
    {
        while true {
            if position == bytes.count {
                if allowingExhaustion { break }
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

    public func next<T>(is sequence: T) throws -> Bool
        where T : Collection, T.Element == UInt8
    {
        let count = sequence.count
        try ensure(count: count)
        return bytes[position..<position+count].elementsEqual(sequence)
    }
}
