import Testing
@testable import Stream

@Test("BufferedStream")
func bufferedStream() async throws {
    let stream = BufferedStream(baseStream: TestStream(), capacity: 10)

    let result = try await stream.write(from: [0, 1, 2, 3, 4], byteCount: 5)
    #expect(result == 5)
    #expect(stream.outputStream.buffered == 5)

    await #expect(throws: StreamError.insufficientData) {
        try await stream.read(count: 5)
    }
    #expect(stream.inputStream.buffered == 0)
    try await stream.outputStream.flush()
    #expect(stream.outputStream.buffered == 0)
    #expect(try await stream.read(count: 5) == [0, 1, 2, 3, 4])
    #expect(stream.inputStream.buffered == 0)
}

@Test("BufferedStream default capacity")
func bufferedStreamDefaultCapacity() async throws {
    let stream = BufferedStream(baseStream: TestStream())
    #expect(stream.inputStream.allocated == 4096)
    #expect(stream.inputStream.buffered == 0)
    #expect(stream.outputStream.allocated == 4096)
    #expect(stream.outputStream.buffered == 0)
}
