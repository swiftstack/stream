public protocol StreamReadable {
    init<T: StreamReader>(from stream: T) async throws
}

public extension StreamReader {
    func read<T: StreamReadable>(_ type: T.Type) async throws -> T {
        return try await T(from: self)
    }
}
