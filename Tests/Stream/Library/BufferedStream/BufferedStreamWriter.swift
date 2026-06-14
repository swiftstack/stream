import Testing
@testable import Stream

@Test("BufferedStreamWriter write byte")
func bufferedStreamWriterWriteByte() async throws {
    let stream = MemoryStream()
    let output = BufferedOutputStream(baseStream: stream, capacity: 5)

    try await output.write(UInt8(42))
    try await output.flush()

    #expect(stream.buffer[..<stream.position].elementsEqual([42]))
}
