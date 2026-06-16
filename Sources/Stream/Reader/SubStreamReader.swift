extension StreamReader {
    // FIXME: Generalize SubStream type
    public func withSubStreamReader<Size: FixedWidthInteger, Result>(
        sizedBy type: Size.Type,
        includingHeader: Bool = false,
        body: (MemoryStream) async throws -> Result
    ) async throws -> Result {
        let length = includingHeader
            ? Int(try await read(type)) - MemoryLayout<Size>.size
            : Int(try await read(type))
        return try await withSubStreamReader(limitedBy: length, body: body)
    }

    // FIXME: Generalize SubStream type
    public func withSubStreamReader<Result>(
        limitedBy limit: Int,
        body: (MemoryStream) async throws -> Result
    ) async throws -> Result {
        let bytes = try await read(count: limit)
        let stream = MemoryStream(bytes)
        return try await body(stream)
    }
}


extension StreamReader {
    // FIXME: Generalize SubStream type
    public func withSubStreamReader<Size: LengthHeader, Result>(
        sizedBy type: Size.Type,
        body: (MemoryStream) async throws -> Result
    ) async throws -> Result {
        let type = try await type.init(from: self)
        return try await withSubStreamReader(limitedBy: type.value, body: body)
    }
}
