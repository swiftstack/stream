extension StreamReader {
    @inlinable
    public func readUntilEnd() async throws -> [UInt8] {
        try await readUntilEnd(body: [UInt8].init)
    }
}
