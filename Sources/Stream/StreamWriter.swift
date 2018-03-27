public protocol StreamWriter: class {
    var buffered: Int { get }
    func write(_ byte: UInt8) throws
    func write<T: BinaryInteger>(_ value: T) throws
    func write(_ bytes: [UInt8]) throws
    func write(_ bytes: UnsafeRawPointer, byteCount: Int) throws
}

extension StreamWriter {
    public func write(_ bytes: [UInt8]) throws {
        try write(bytes, byteCount: bytes.count)
    }

    public func write(_ string: String) throws {
        try write([UInt8](string.utf8))
    }
}

public protocol StreamWritable {
    func write(to stream: StreamWriter) throws
}
