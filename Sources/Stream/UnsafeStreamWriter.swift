protocol UnsafeStreamWriter: OutputStream {
    var buffered: Int { get }
    func write(_ byte: UInt8) throws
}
