extension StreamWriter {
    // FIXME: Generalize SubStream type
    public func withSubStreamWriter<Size: FixedWidthInteger>(
        sizedBy type: Size.Type,
        includingHeader: Bool = false,
        task: (MemoryStream) async throws -> Void
    ) async throws {
        let output = MemoryStream()
        try await task(output)
        let sizeHeader = includingHeader
            ? Size(output.position + MemoryLayout<Size>.size)
            : Size(output.position)
        try await write(sizeHeader)
        try await write(output.buffer.baseAddress!, byteCount: output.position)
    }
}

