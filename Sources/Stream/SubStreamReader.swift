public protocol SubStreamReader: StreamReader {
    var limit: Int { get }
    var isEmpty: Bool { get }
}

extension UnsafeRawInputStream: SubStreamReader {
    public var limit: Int {
        return count
    }
}

extension StreamReader {
    public func withSubStreamReader<Size: FixedWidthInteger, Result>(
        sizedBy type: Size.Type,
        includingHeader: Bool = false,
        body: (SubStreamReader) throws -> Result) throws -> Result
    {
        let length = includingHeader
            ? Int(try read(type)) - MemoryLayout<Size>.size
            : Int(try read(type))
        return try withSubStreamReader(limitedBy: length, body: body)
    }

    public func withSubStreamReader<Result>(
        limitedBy limit: Int,
        body: (SubStreamReader) throws -> Result) throws -> Result
    {
        return try read(count: limit) { bytes in
            let stream = UnsafeRawInputStream(
                pointer: bytes.baseAddress!,
                count: bytes.count)
            return try body(stream)
        }
    }
}
