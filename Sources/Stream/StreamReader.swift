public protocol StreamReadable {
    init(from stream: StreamReader) throws
}

extension StreamReader {
    func read<T: StreamReadable>() throws -> T {
        return try T(from: self)
    }
}

public protocol StreamReader: class {
    func cache(count: Int) throws -> Bool

    func peek() throws -> UInt8

    func peek<T>(
        count: Int,
        body: (UnsafeRawBufferPointer) throws -> T
    ) throws -> T

    func read<T: BinaryInteger>(_ type: T.Type) throws -> T

    func read<T>(
        count: Int,
        body: (UnsafeRawBufferPointer) throws -> T
    ) throws -> T

    func read<T>(
        untilEnd: Bool,
        while predicate: (UInt8) -> Bool,
        body: (UnsafeRawBufferPointer) throws -> T
    ) throws -> T

    func consume(count: Int) throws

    func consume(_ byte: UInt8) throws -> Bool

    func consume(
        untilEnd: Bool,
        while predicate: (UInt8) -> Bool
    ) throws
}

extension StreamReader {
    @inline(__always)
    public func read<T>(
        until byte: UInt8,
        body: (UnsafeRawBufferPointer) throws -> T) throws -> T
    {
        return try read(
            untilEnd: false,
            while: { $0 != byte },
            body: body)
    }

    public func consume(until byte: UInt8) throws {
        try consume(untilEnd: false, while: { $0 != byte })
    }

    @_inlineable
    public func consume<T>(sequence bytes: T) throws -> Bool
        where T: Collection, T.Element == UInt8
    {
        guard try cache(count: bytes.count) else {
            throw StreamError.insufficientData
        }
        guard try next(is: bytes) else {
            return false
        }
        try consume(count: bytes.count)
        return true
    }

    @_inlineable
    public func next<T: Collection>(is elements: T) throws -> Bool
        where T.Element == UInt8
    {
        return try peek(count: elements.count) { bytes in
            return bytes.elementsEqual(elements)
        }
    }
}

// MARK: untilEnd = true by default

extension StreamReader {
    @inline(__always)
    public func read<T>(
        while predicate: (UInt8) -> Bool,
        body: (UnsafeRawBufferPointer) throws -> T) throws -> T
    {
        return try read(untilEnd: true, while: predicate, body: body)
    }

    @inline(__always)
    public func consume(while predicate: (UInt8) -> Bool) throws {
        try consume(untilEnd: true, while: predicate)
    }
}

// MARK: [UInt8]

extension StreamReader {
    public func read(until byte: UInt8) throws -> [UInt8] {
        return try read(until: byte, body: [UInt8].init)
    }

    @_inlineable
    public func read(count: Int) throws -> [UInt8] {
        return try read(count: count, body: [UInt8].init)
    }

    @_inlineable
    public func read(
        untilEnd: Bool = true,
        while predicate: (UInt8) -> Bool) throws -> [UInt8]
    {
        return try read(
            untilEnd: untilEnd,
            while: predicate,
            body: [UInt8].init)
    }
}
