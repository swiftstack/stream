extension StreamReader {
    @inlinable
    public func peek(count: Int, as type: String.Type) async throws -> String {
        try await peek(count: count) { bytes in
            String(decoding: bytes, as: UTF8.self)
        }
    }

    @inlinable
    public func read(count: Int, as type: String.Type) async throws -> String {
        return try await read(count: count) { bytes in
            String(decoding: bytes, as: UTF8.self)
        }
    }

    @inlinable
    public func read(
        mode: PredicateMode,
        while predicate: (UInt8) -> Bool,
        as type: String.Type
    ) async throws -> String {
        try await read(mode: mode, while: predicate) { bytes in
            String(decoding: bytes, as: UTF8.self)
        }
    }

    @inlinable
    public func readUntilEnd(as type: String.Type) async throws -> String {
        return try await read(mode: .untilEnd, while: { _ in true }, as: type)
    }
}
