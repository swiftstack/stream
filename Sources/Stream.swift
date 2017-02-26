public enum StreamError: Error {
    case full
    case eof
    case notEnoughSpace
    case insufficientData
}

public protocol Stream: InputStream, OutputStream {}

public protocol InputStream {
    func read(to buffer: UnsafeMutableRawPointer, count: Int) throws -> Int
}

public protocol OutputStream {
    func write(_ bytes: UnsafeRawPointer, count: Int) throws -> Int
}

extension InputStream {
    public func read(to buffer: UnsafeMutableRawPointer, offset: Int, count: Int) throws -> Int {
        return try read(to: buffer.advanced(by: offset), count: count)
    }

    public func read(to buffer: inout [UInt8]) throws -> Int {
        return try read(to: &buffer, count: buffer.count)
    }
}

extension OutputStream {
    public func write(_ bytes: UnsafeRawPointer, offset: Int, count: Int) throws -> Int {
        return try write(bytes.advanced(by: offset), count: count)
    }

    public func write(_ bytes: [UInt8]) throws -> Int {
        return try write(bytes, count: bytes.count)
    }
}
