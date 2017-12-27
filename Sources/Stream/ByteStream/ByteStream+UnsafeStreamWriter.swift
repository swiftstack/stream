// Convenience conformance

extension OutputByteStream: UnsafeStreamWriter {
    public var buffered: Int {
        return bytes.count - position
    }

    public func write(_ bytes: UnsafeRawPointer, byteCount: Int) throws {
        var written = 0
        while written < byteCount {
            let count: Int = try write(bytes, byteCount: byteCount)
            guard count > 0 else {
                throw StreamError.insufficientData
            }
            written += count
        }
    }
}
