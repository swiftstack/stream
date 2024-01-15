import Test
@testable import Stream

extension BufferedStream {
    func read(count: Int) async throws -> [UInt8] {
        var buffer = [UInt8](repeating: 0, count: count)
        let read = try await self.read(to: &buffer)
        return [UInt8](buffer[..<read])
    }
}

test("BufferedStream") {
    let stream = BufferedStream(baseStream: TestStream(), capacity: 10)

    let result = try await stream.write(from: [0, 1, 2, 3, 4])
    expect(result == 5)
    expect(stream.outputStream.buffered == 5)

    expect(try await stream.read(count: 5) == [])
    expect(stream.inputStream.buffered == 0)
    expect(try await stream.outputStream.flush() == ())
    expect(stream.outputStream.buffered == 0)
    expect(try await stream.read(count: 5) == [0, 1, 2, 3, 4])
    expect(stream.inputStream.buffered == 0)
}

test("BufferedStreamDefaultCapacity") {
    let stream = BufferedStream(baseStream: TestStream())
    expect(stream.inputStream.allocated == 4096)
    expect(stream.inputStream.buffered == 0)
    expect(stream.outputStream.allocated == 4096)
    expect(stream.outputStream.buffered == 0)
}

await run()
