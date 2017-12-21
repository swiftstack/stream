public protocol UnsafeStreamReader: class {
    var buffered: Int { get }

    /// Get the next 'count' bytes (if present)
    /// without advancing current read position
    func peek(count: Int) throws -> UnsafeRawBufferPointer?

    func read() throws -> UInt8

    func read(count: Int) throws -> UnsafeRawBufferPointer

    func read(
        while predicate: (UInt8) -> Bool,
        allowingExhaustion: Bool
    ) throws -> UnsafeRawBufferPointer

    func consume(count: Int) throws

    func consume(_ byte: UInt8) throws -> Bool

    func consume(
        while predicate: (UInt8) -> Bool
    ) throws

    func consume(
        while predicate: (UInt8) -> Bool,
        allowingExhaustion: Bool
    ) throws
}

extension UnsafeStreamReader {
    @inline(__always)
    public func read(
        while predicate: (UInt8) -> Bool
    ) throws -> UnsafeRawBufferPointer {
        return try read(while: predicate, allowingExhaustion: true)
    }

    @inline(__always)
    public func consume(
        while predicate: (UInt8) -> Bool
    ) throws {
        try consume(while: predicate, allowingExhaustion: true)
    }

    @inline(__always)
    public func read(until byte: UInt8) throws -> UnsafeRawBufferPointer {
        return try read(while: { $0 != byte }, allowingExhaustion: false)
    }

    @inline(__always)
    public func consume(until byte: UInt8) throws {
        try consume(while: { $0 != byte }, allowingExhaustion: false)
    }
}
