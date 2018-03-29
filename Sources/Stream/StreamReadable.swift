public protocol StreamReadable {
    init(from stream: StreamReader) throws
}

extension StreamReader {
    func read<T: StreamReadable>(_ type: T.Type) throws -> T {
        return try T(from: self)
    }
}
