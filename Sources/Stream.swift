public enum StreamError: Error {
    case notEnoughSpace
    case insufficientData
    case invalidSeekOffset
}

public protocol Stream: InputStream, OutputStream {}

public protocol InputStream {
    func read(to buffer: UnsafeMutableRawBufferPointer) throws -> Int
}

public protocol OutputStream {
    func write(_ bytes: UnsafeRawBufferPointer) throws -> Int
}

extension InputStream {
    public func read(to buffer: UnsafeMutableRawPointer, count: Int) throws -> Int {
        return try read(to: UnsafeMutableRawBufferPointer(
            start: buffer,
            count: count))
    }

    public func read(to buffer: inout [UInt8]) throws -> Int {
        return try buffer.withUnsafeMutableBytes { buffer in
            return try read(to: buffer)
        }
    }
}

extension OutputStream {
    public func write(_ bytes: UnsafeRawPointer, count: Int) throws -> Int {
        return try write(UnsafeRawBufferPointer(start: bytes, count: count))
    }

    public func write(_ slice: ArraySlice<UInt8>) throws -> Int {
        return try slice.withUnsafeBytes { buffer in
            return try write(buffer)
        }
    }

    public func write(_ bytes: [UInt8]) throws -> Int {
        return try bytes.withUnsafeBytes { buffer in
            return try write(buffer)
        }
    }
}
