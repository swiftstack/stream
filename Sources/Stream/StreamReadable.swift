public protocol StreamReadable {
    init(from stream: StreamReader) throws(StreamError)
}

extension StreamReader {
    func read<T: StreamReadable>(_ type: T.Type) throws(StreamError) -> T {
        return try T(from: self)
    }
}
