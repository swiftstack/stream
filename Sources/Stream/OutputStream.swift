public protocol OutputStream {
    func write(_ bytes: UnsafeRawPointer, byteCount: Int) throws -> Int
}

extension OutputStream {
    @inline(__always)
    public func write(_ bytes: UnsafeRawBufferPointer) throws -> Int {
        return try write(bytes.baseAddress!, byteCount: bytes.count)
    }

    @inline(__always)
    public func write(_ bytes: ArraySlice<UInt8>) throws -> Int {
        return try bytes.withUnsafeBytes { buffer in
            return try write(buffer)
        }
    }

    @inline(__always)
    public func write(_ bytes: [UInt8]) throws -> Int {
        return try bytes.withUnsafeBytes { buffer in
            return try write(buffer)
        }
    }
}

extension OutputStream {
    @_inlineable
    public func copyBytes<T: InputStream>(
        from input: inout T,
        bufferSize: Int = 4096) throws -> Int
    {
        var total = 0
        var buffer = [UInt8](repeating: 0, count: bufferSize)

        while true {
            let read = try input.read(to: &buffer)
            guard read > 0 else {
                return total
            }
            total = total &+ read

            var index = 0
            while index < read {
                let written = try write(buffer[index..<read])
                guard written > 0 else {
                    throw StreamError.notEnoughSpace
                }
                index += written
            }
        }
    }
}
