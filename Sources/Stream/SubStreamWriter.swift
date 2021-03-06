public protocol SubStreamWriter: StreamWriter {
    var count: Int { get }
}

extension ByteArrayOutputStream: SubStreamWriter {
    public var count: Int {
        return bytes.count
    }
}

extension StreamWriter {
    public func withSubStreamWriter<Size: FixedWidthInteger>(
        sizedBy type: Size.Type,
        includingHeader: Bool = false,
        task: (SubStreamWriter) async throws -> Void) async throws
    {
        let output = ByteArrayOutputStream()
        try await task(output)
        let sizeHeader = includingHeader
            ? Size(output.bytes.count + MemoryLayout<Size>.size)
            : Size(output.bytes.count)
        try await write(sizeHeader)
        try await write(output.bytes)
    }
}
