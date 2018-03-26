public protocol InputStream {
    func read(to pointer: UnsafeMutableRawPointer, byteCount: Int) throws -> Int
}

extension InputStream {
    @inline(__always)
    public func read(to buffer: UnsafeMutableRawBufferPointer) throws -> Int {
        return try read(to: buffer.baseAddress!, byteCount: buffer.count)
    }

    @inline(__always)
    public func read(to buffer: inout ArraySlice<UInt8>) throws -> Int {
        return try buffer.withUnsafeMutableBytes { buffer in
            return try read(to: buffer)
        }
    }

    @inline(__always)
    public func read(to buffer: inout [UInt8]) throws -> Int {
        return try buffer.withUnsafeMutableBytes { buffer in
            return try read(to: buffer)
        }
    }
}
