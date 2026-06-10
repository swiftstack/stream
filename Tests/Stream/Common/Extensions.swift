import Stream

extension TestStream {
    func write(
        from array: [Int],
        byteCount: Int
    ) throws(StreamError) -> Int {
        var array = array.map(UInt8.init)
        return write(from: &array, byteCount: byteCount)
    }
}

extension MemoryStream {
    func write(
        from array: [Int],
        byteCount: Int
    ) throws(StreamError) -> Int {
        var array = array.map(UInt8.init)
        return try write(from: &array, byteCount: byteCount)
    }
}

extension ByteArrayOutputStream {
    func write(
        from array: [Int],
        byteCount: Int
    ) -> Int {
        var array = array.map(UInt8.init)
        return write(from: &array, byteCount: byteCount)
    }
}

extension BufferedStream {
    func write(
        from array: [Int],
        byteCount: Int
    ) async throws -> Int {
        var array = array.map(UInt8.init)
        return try await write(from: &array, byteCount: byteCount)
    }
}

extension BufferedOutputStream {
    func write(
        from array: [Int],
        byteCount: Int
    ) async throws -> Int {
        var array = array.map(UInt8.init)
        return try await write(from: &array, byteCount: byteCount)
    }
}
