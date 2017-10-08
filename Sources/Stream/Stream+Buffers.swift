extension InputStream {
    @inline(__always)
    public mutating func read(
        to buffer: UnsafeMutableRawPointer, count: Int
    ) throws -> Int {
        return try read(to: UnsafeMutableRawBufferPointer(
            start: buffer,
            count: count))
    }

    @inline(__always)
    public mutating func read(to buffer: inout ArraySlice<UInt8>) throws -> Int {
        return try buffer.withUnsafeMutableBytes { buffer in
            return try read(to: buffer)
        }
    }

    @inline(__always)
    public mutating func read(to buffer: inout [UInt8]) throws -> Int {
        return try buffer.withUnsafeMutableBytes { buffer in
            return try read(to: buffer)
        }
    }
}

extension OutputStream {
    @inline(__always)
    public mutating func write(
        _ bytes: UnsafeRawPointer, count: Int
    ) throws -> Int {
        return try write(UnsafeRawBufferPointer(start: bytes, count: count))
    }

    @inline(__always)
    public mutating func write(_ bytes: ArraySlice<UInt8>) throws -> Int {
        return try bytes.withUnsafeBytes { buffer in
            return try write(buffer)
        }
    }

    @inline(__always)
    public mutating func write(_ bytes: [UInt8]) throws -> Int {
        return try bytes.withUnsafeBytes { buffer in
            return try write(buffer)
        }
    }
}
