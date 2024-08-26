import Testing
@testable import Stream

@Test("ByteArrayInputStream read")
func byteArrayInputStreamRead() async throws {
    let inputStream = ByteArrayInputStream([])
    var buffer = [UInt8]()
    #expect(try inputStream.read(to: &buffer, byteCount: 0) == 0)
}

@Test("ByteArrayInputStream advance position before callback")
func byteArrayInputStreamAdvancePositionBeforeCallback() async throws {
    let input = ByteArrayInputStream([0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
    try await input.readUntilEnd { _ in
        #expect(input.position == input.bytes.count)
    }
}
