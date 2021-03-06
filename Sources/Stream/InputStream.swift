public protocol InputStream {
    func read(
        to pointer: UnsafeMutableRawPointer,
        byteCount: Int
    ) async throws -> Int
}

// @testable
extension InputStream {
    func read(
        to buffer: UnsafeMutableRawBufferPointer
    ) async throws -> Int {
        return try await read(to: buffer.baseAddress!, byteCount: buffer.count)
    }

    func read(to buffer: inout ArraySlice<UInt8>) async throws -> Int {
        // FIXME: [Concurrency]
        // return try buffer.withUnsafeMutableBytes { buffer in
        //     return try await read(to: buffer)
        // }
        let temp = UnsafeMutableRawBufferPointer.allocate(
            byteCount: buffer.count,
            alignment: MemoryLayout<UInt8>.size)
        defer { temp.deallocate() }

        let count = try await read(to: temp)

        buffer.withUnsafeMutableBytes { buffer in
            buffer.copyBytes(from: temp)
        }

        return count
    }

    func read(to buffer: inout [UInt8]) async throws -> Int {
        // FIXME: [Concurrency]
        // return try buffer.withUnsafeMutableBytes { buffer in
        //     return try await read(to: buffer)
        // }
        let temp = UnsafeMutableRawBufferPointer.allocate(
            byteCount: buffer.count,
            alignment: MemoryLayout<UInt8>.size)
        defer { temp.deallocate() }

        let count = try await read(to: temp)

        buffer.withUnsafeMutableBytes { buffer in
            buffer.copyBytes(from: temp)
        }

        return count
    }
}
