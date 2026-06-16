public protocol StreamWritable {
    func write<T: StreamWriter>(to stream: T) async throws
}

public extension StreamWriter {
    func write<T: StreamWritable>(_ value: T) async throws {
        try await value.write(to: self)
    }
}
