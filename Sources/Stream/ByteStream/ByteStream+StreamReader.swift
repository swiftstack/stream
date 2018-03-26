// Convenience conformance

extension InputByteStream: StreamReader {
    public var buffered: Int {
        return bytes.count - position
    }

    func ensure(count: Int) throws {
        guard buffered >= count else {
            throw StreamError.insufficientData
        }
    }

    private func _read(count: Int) throws -> ArraySlice<UInt8> {
        try ensure(count: count)
        defer { position += count }
        return bytes[position..<position+count]
    }

    public func read(count: Int) throws -> [UInt8] {
        return [UInt8](try _read(count: count))
    }

    public func read<T>(
        count: Int,
        body: (UnsafeRawBufferPointer) throws -> T) throws -> T
    {
        let slice = try _read(count: count) as ArraySlice<UInt8>
        return try slice.withUnsafeBytes { bytes in
            return try body(bytes)
        }
    }

    private func _read(
        while predicate: (UInt8) -> Bool,
        allowingExhaustion: Bool) throws -> ArraySlice<UInt8>
    {
        var read = 0
        defer { position += read }
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
        return try slice.withUnsafeBytes { bytes in
            return try body(bytes)
        }
    }

    public func read<T: RawBufferInitializable>(
        _ type: T.Type,
        while predicate: (UInt8) -> Bool,
        allowingExhaustion: Bool) throws -> T
    {
        let slice = try _read(
            while: predicate,
            allowingExhaustion: allowingExhaustion)
        return try slice.withUnsafeBytes { bytes in
            return try T(buffer: bytes)
        }
    }

    public func consume(count: Int) throws {
        try ensure(count: count)
        position += count
    }

    public func consume(_ byte: UInt8) throws -> Bool {
        try ensure(count: 1)
        guard bytes[position] == byte else {
            return false
        }
        position += 1
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
            position += 1
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
