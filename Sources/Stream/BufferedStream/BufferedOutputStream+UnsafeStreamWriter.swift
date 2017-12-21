extension BufferedOutputStream: UnsafeStreamWriter {
    public func write(_ byte: UInt8) throws {
        if available <= 0 {
            try flush()
        }
        storage.advanced(by: buffered)
            .assumingMemoryBound(to: UInt8.self)
            .pointee = byte
        buffered += 1
    }
}
