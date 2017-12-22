// Convenience conformance

extension OutputByteStream: UnsafeStreamWriter {
    public var buffered: Int {
        return bytes.count - position
    }
}
