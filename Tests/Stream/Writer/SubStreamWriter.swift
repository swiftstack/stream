import Testing
@testable import Stream

@Test("SubStreamWriter withSubStreamWriter(sizedBy:)")
func writerSizedBy() async throws {
    let message = "Hello, World!"
    let stream = MemoryStream(
        capacity: message.count + MemoryLayout<UInt16>.size
    )
    try await stream.withSubStreamWriter(sizedBy: UInt16.self) { stream in
        try await stream.write(message)
    }
    #expect(stream.buffer[..<2].elementsEqual([0x00, 0x0D]))
    #expect(stream.buffer[2...].elementsEqual(message.utf8))
    print([UInt8](stream.buffer[2...]))
}

@Test("SubStreamWriter withSubStreamWriter(sizedBy:includingHeader:)")
func writerSizedByIncludingHeader() async throws {
    let message = "Hello, World!"
    let stream = MemoryStream(
        capacity: message.count + MemoryLayout<UInt16>.size
    )
    try await stream.withSubStreamWriter(
        sizedBy: UInt16.self,
        includingHeader: true
    ) { stream in
        try await stream.write(message)
    }
    #expect(stream.buffer[..<2].elementsEqual([0x00, 0x0F]))
    #expect(stream.buffer[2...].elementsEqual(message.utf8))
}
