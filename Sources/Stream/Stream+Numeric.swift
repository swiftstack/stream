extension InputStream {
    @_inlineable
    public func read<T: BinaryInteger>(_ type: T.Type) throws -> T {
        var result: T = 0
        let size = MemoryLayout<T>.size
        try withUnsafeMutablePointer(to: &result) { pointer in
            var total = 0
            while total < size {
                let pointer = pointer.advanced(by: total)
                let read = try self.read(to: pointer, byteCount: size - total)
                guard read > 0 else {
                    throw StreamError.insufficientData
                }
                total += read
            }
        }
        return result
    }
}

extension OutputStream {
    @_inlineable
    public func write<T: BinaryInteger>(_ value: T) throws {
        var copy = value
        let size = MemoryLayout<T>.size
        try withUnsafePointer(to: &copy) { pointer in
            var total = 0
            while total < size {
                let pointer = pointer.advanced(by: total)
                let written = try write(pointer, byteCount: size - total)
                guard written > 0 else {
                    throw StreamError.notEnoughSpace
                }
                total += written
            }
        }
    }
}
