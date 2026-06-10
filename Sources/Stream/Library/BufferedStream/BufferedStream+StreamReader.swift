extension BufferedStream: StreamReader {
    public func cache(count: Int) async throws(StreamError) -> Bool {
        return try await inputStream.cache(count: count)
    }

    public func peek() async throws(StreamError) -> UInt8 {
        return try await inputStream.peek()
    }

    public func peek<T>(
        count: Int,
        body: (UnsafeRawBufferPointer) throws(StreamError) -> T
    ) async throws(StreamError) -> T {
        return try await inputStream.peek(count: count, body: body)
    }

    public func read<T: FixedWidthInteger>(_ type: T.Type) async throws(StreamError) -> T {
        return try await inputStream.read(type)
    }

    public func read<T>(
        count: Int,
        body: (UnsafeRawBufferPointer) throws(StreamError) -> T
    ) async throws(StreamError) -> T {
        return try await inputStream.read(count: count, body: body)
    }

    public func read<T>(
        mode: PredicateMode,
        while predicate: (UInt8) -> Bool,
        body: (UnsafeRawBufferPointer) throws(StreamError) -> T
    ) async throws(StreamError) -> T {
        return try await inputStream.read(
            mode: mode, while: predicate, body: body)
    }

    public func consume(count: Int) async throws(StreamError) {
        return try await inputStream.consume(count: count)
    }

    public func consume(_ byte: UInt8) async throws(StreamError) -> Bool {
        return try await inputStream.consume(byte)
    }

    public func consume(
        mode: PredicateMode,
        while predicate: (UInt8) -> Bool
    ) async throws(StreamError) {
        try await inputStream.consume(mode: mode, while: predicate)
    }
}
