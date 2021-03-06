public protocol SubStreamReader: StreamReader {
    var limit: Int { get }
    var isEmpty: Bool { get }
}

extension ByteArrayInputStream: SubStreamReader {
    public var limit: Int {
        return bytes.count
    }
}

extension StreamReader {
    public func withSubStreamReader<Size: FixedWidthInteger, Result>(
        sizedBy type: Size.Type,
        includingHeader: Bool = false,
        body: (SubStreamReader) async throws -> Result) async throws -> Result
    {
        let length = includingHeader
            ? Int(try await read(type)) - MemoryLayout<Size>.size
            : Int(try await read(type))
        return try await withSubStreamReader(limitedBy: length, body: body)
    }

    public func withSubStreamReader<Result>(
        limitedBy limit: Int,
        body: (SubStreamReader) async throws -> Result) async throws -> Result
    {
        // FIXME: [Concurrency] optimize
        let bytes = try await read(count: limit)
        let stream = ByteArrayInputStream(bytes)
        return try await body(stream)
    }
}
