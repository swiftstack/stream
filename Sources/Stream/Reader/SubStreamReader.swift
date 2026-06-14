extension StreamReader {
    public func withSubStreamReader<Size: FixedWidthInteger, Result>(
        sizedBy type: Size.Type,
        includingHeader: Bool = false,
        body: (StreamReader) async throws -> Result
    ) async throws -> Result {
        let length = includingHeader
            ? Int(try await read(type)) - MemoryLayout<Size>.size
            : Int(try await read(type))
        return try await withSubStreamReader(limitedBy: length, body: body)
    }

    // TODO: optimize
    public func withSubStreamReader<Result>(
        limitedBy limit: Int,
        body: (StreamReader) async throws -> Result
    ) async throws -> Result {
        let bytes = try await read(count: limit)
        let stream = MemoryStream(bytes)
        return try await body(stream)
    }
}
