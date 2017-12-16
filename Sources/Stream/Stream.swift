public enum StreamError: Error {
    case readLessThenRequired
    case writtenLessThenRequired
}

public protocol Stream: InputStream, OutputStream {}

public protocol InputStream {
    func read(to pointer: UnsafeMutableRawPointer, byteCount: Int) throws -> Int
}

public protocol OutputStream {
    func write(_ bytes: UnsafeRawPointer, byteCount: Int) throws -> Int
}
