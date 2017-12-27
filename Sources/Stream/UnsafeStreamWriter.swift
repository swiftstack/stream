public protocol UnsafeStreamWriter: class {
    var buffered: Int { get }
    func write(_ bytes: UnsafeRawPointer, byteCount: Int) throws
    func write(_ byte: UInt8) throws
}

extension UnsafeStreamWriter {
    public func write(_ bytes: [UInt8]) throws {
        try write(bytes, byteCount: bytes.count)
    }
}
