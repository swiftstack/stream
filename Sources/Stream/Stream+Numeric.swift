extension InputStream {
    @inline(__always)
    public mutating func read<T: BinaryInteger>(_ type: T.Type) throws -> T {
        var result: T = 0
        try withUnsafeMutableBytes(of: &result) { bytes in
            guard try read(to: bytes) == MemoryLayout<T>.size else {
                throw StreamError.readLessThenRequired
            }
        }
        return result
    }
}

extension OutputStream {
    @inline(__always)
    public mutating func write<T: BinaryInteger>(_ value: T) throws {
        var value = value
        try withUnsafeBytes(of: &value) { bytes in
            guard try write(bytes) == MemoryLayout<T>.size else {
                throw StreamError.writtenLessThenRequired
            }
        }
    }
}
