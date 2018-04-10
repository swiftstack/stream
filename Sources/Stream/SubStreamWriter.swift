public protocol SubStreamWriter: StreamWriter {
    var count: Int { get }
}

extension OutputByteStream: SubStreamWriter {
    public var count: Int {
        return bytes.count
    }
}

extension StreamWriter {
    public func withSubStream<T: FixedWidthInteger>(
        sizedBy type: T.Type,
        task: (SubStreamWriter) throws -> Void) throws
    {
        let output = OutputByteStream()
        try task(output)
        try write(T(output.bytes.count))
        try write(output.bytes)
    }
}
