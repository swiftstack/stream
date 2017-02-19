public enum StreamError: Error {
    case noSpaceAvailable
}

public protocol Stream: InputStream, OutputStream {}

public protocol InputStream {
    func read(to buffer: UnsafeMutableRawPointer, count: Int) throws -> Int
}

public protocol OutputStream {
    func write(from buffer: UnsafeRawPointer, count: Int) throws -> Int
}

extension InputStream {
    public func read(to buffer: UnsafeMutableRawPointer, offset: Int, count: Int) throws -> Int {
        return try read(to: buffer.advanced(by: offset), count: count)
    }
}

extension OutputStream {
    public func write(from buffer: UnsafeRawPointer, offset: Int, count: Int) throws -> Int {
        return try write(from: buffer.advanced(by: offset), count: count)
    }
}
