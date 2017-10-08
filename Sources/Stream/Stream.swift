public enum StreamError: Error {
    case readLessThenRequired
    case writtenLessThenRequired
}

public protocol Stream: InputStream, OutputStream {}

public protocol InputStream {
    mutating func read(to buffer: UnsafeMutableRawBufferPointer) throws -> Int
}

public protocol OutputStream {
    mutating func write(_ bytes: UnsafeRawBufferPointer) throws -> Int
}
