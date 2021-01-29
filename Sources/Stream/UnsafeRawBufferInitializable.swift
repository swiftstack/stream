public protocol UnsafeRawBufferInitializable {
    init(_ buffer: UnsafeRawBufferPointer)
}

extension String: UnsafeRawBufferInitializable {
    public init(_ buffer: UnsafeRawBufferPointer) {
        self.init(decoding: buffer, as: UTF8.self)
    }
}

extension Array: UnsafeRawBufferInitializable where Element == UInt8 {}

extension StreamReader {
    @inlinable
    public func peek<T>(count: Int, as type: T.Type) async throws -> T
        where T: UnsafeRawBufferInitializable
    {
        return try await peek(count: count) { bytes in
            return T(bytes)
        }
    }

    @inlinable
    public func read<T>(count: Int, as type: T.Type) async throws -> T
        where T: UnsafeRawBufferInitializable
    {
        return try await read(count: count) { bytes in
            return T(bytes)
        }
    }

    @inlinable
    public func read<T: UnsafeRawBufferInitializable>(
        mode: PredicateMode,
        while predicate: (UInt8) -> Bool,
        as type: T.Type) async throws -> T
    {
        return try await read(mode: mode, while: predicate) { bytes in
            return T(bytes)
        }
    }

    @inlinable
    public func readUntilEnd<T>(as type: T.Type) async throws -> T
        where T: UnsafeRawBufferInitializable
    {
        return try await read(mode: .untilEnd, while: { _ in true }, as: type)
    }

    public func readUntilEnd() async throws -> [UInt8] {
        return try await readUntilEnd(as: [UInt8].self)
    }
}
