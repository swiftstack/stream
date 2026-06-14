extension MemoryStream: StreamWriter {
    public func write(_ byte: UInt8) throws {
        guard remain > 0 else {
            throw StreamError.notEnoughSpace
        }
        buffer[position] = byte
        position += 1
    }

    public func write<T: FixedWidthInteger>(_ value: T) throws {
        var value = value.bigEndian
        try withUnsafeBytes(of: &value, write)
    }

    public func write(_ bytes: UnsafeRawPointer, byteCount: Int) throws {
        guard try write(from: bytes, byteCount: byteCount) == byteCount else {
            throw StreamError.notEnoughSpace
        }
    }

    public func flush() throws {
    }
}

extension MemoryStream {
    public func write(_ bytes: UnsafeRawBufferPointer) throws {
        try write(bytes.baseAddress!, byteCount: bytes.count)
    }

    public func write(_ bytes: [UInt8]) throws {
        try bytes.withUnsafeBufferPointer { pointer in
            try write(pointer.baseAddress!, byteCount: pointer.count)
        }
    }

    public func write(_ string: String) throws {
        var string = string
        try string.withUTF8 { bytes in
            try write(bytes.baseAddress!, byteCount: bytes.count)
        }
    }
}
