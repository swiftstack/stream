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
    public func withSubStream<H: FixedWidthInteger, T>(
        sizedBy type: H.Type,
        body: (SubStreamReader) throws -> T) throws -> T
    {
        let length = try read(type)
        return try withSubStream(limitedBy: Int(length), body: body)
    }

    public func withSubStream<T>(
        limitedBy limit: Int,
        body: (SubStreamReader) throws -> T) throws -> T
    {
        return try read(count: limit) { bytes in
            let stream = UnsafeRawInputStream(
                pointer: bytes.baseAddress!,
                count: bytes.count)
            return try body(stream)
        }
    }
}
