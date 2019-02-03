public protocol SubStreamWriter: StreamWriter {
    var count: Int { get }
}

extension OutputByteStream: SubStreamWriter {
    public var count: Int {
        return bytes.count
    }
}

extension StreamWriter {
    public func withSubStreamWriter<Size: FixedWidthInteger>(
        sizedBy type: Size.Type,
        includingHeader: Bool = false,
        task: (SubStreamWriter) throws -> Void) throws
    {
        let output = OutputByteStream()
        try task(output)
        let sizeHeader = includingHeader
            ? Size(output.bytes.count + MemoryLayout<Size>.size)
            : Size(output.bytes.count)
        try write(sizeHeader)
        try write(output.bytes)
    }
}
