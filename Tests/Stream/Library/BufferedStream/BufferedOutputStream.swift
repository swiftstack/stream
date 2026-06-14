import Testing
@testable import Stream

@Test("BufferedOutputStream")
func bufferedOutputStream() async throws {
    let byteStream = TestStream()
    let stream = BufferedOutputStream(baseStream: byteStream, capacity: 10)
    #expect(stream.allocated == 10)
    #expect(stream.buffered == 0)

    #expect(try await stream.write(from: [0, 1, 2, 3, 4], byteCount: 5) == 5)
    #expect(stream.buffered == 5)
    #expect(try await stream.write(from: [5, 6], byteCount: 2) == 2)
    #expect(stream.buffered == 7)
    #expect(try await stream.write(from: [7, 8, 9], byteCount: 3) == 3)
    #expect(stream.buffered == 0)

    #expect(byteStream.bytes == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
    byteStream.bytes = []

    #expect(
        try await stream.write(
            from: [0, 1, 2, 3, 4, 5, 6, 7, 8],
            byteCount: 9
        ) == 9
    )
    #expect(stream.buffered == 9)
    #expect(
        try await stream.write(
            from: [9, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
            byteCount: 13
        )
        ==
        13
    )
    #expect(stream.buffered == 0)

    #expect(byteStream.bytes == [
        0, 1, 2, 3, 4, 5, 6, 7, 8,
        9, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11
    ])
    byteStream.bytes = []

    #expect(
        try await stream.write(
            from: [0, 1, 2, 3, 4, 5, 6, 7, 8],
            byteCount: 9
        ) == 9
    )
    #expect(stream.buffered == 9)
    #expect(try await stream.write(from: [9, 0, 1], byteCount: 3) == 3)
    #expect(stream.buffered == 2)

    #expect(byteStream.bytes == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
    byteStream.bytes = []

    #expect(try await stream.flush() == ())
    #expect(stream.buffered == 0)

    #expect(byteStream.bytes == [0, 1])
}

@Test("BufferedOutputStream default capacity")
func bufferedOutputStreamDefaultCapacity() async throws {
    let stream = BufferedOutputStream(baseStream: MemoryStream())
    #expect(stream.allocated == 256)
    #expect(stream.buffered == 0)
}
