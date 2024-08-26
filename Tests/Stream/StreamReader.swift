import Testing
@testable import Stream

@Test("StreamReader readUntilEnd()")
func untilEnd() async throws {
    let helloBytes = [UInt8]("Hello, World!".utf8)
    let stream = ByteArrayInputStream(helloBytes)
    let bytes = try await stream.readUntilEnd()
    #expect(bytes == helloBytes)
}

@Test("StreamReader readUntilEnd(as: String.self)")
func untilEndAsString() async throws {
    let helloString = "Hello, World!"
    let helloBytes = [UInt8](helloString.utf8)
    let stream = ByteArrayInputStream(helloBytes)
    let string = try await stream.readUntilEnd(as: String.self)
    #expect(string == helloString)
}

@Test("StreamReader readLine()")
func readLine() async throws {
    let lines = "Hello, World!\r\nHello, World!\r\n"
    let stream = ByteArrayInputStream([UInt8](lines.utf8))

    #expect(try await stream.readLine() == "Hello, World!")
    #expect(try await stream.readLine() == "Hello, World!")
    #expect(try await stream.readLine() == nil)
}
