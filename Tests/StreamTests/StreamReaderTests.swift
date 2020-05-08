import Test
@testable import Stream

class StreamReaderTests: TestCase {
    func testUntilEnd() throws {
        let helloBytes = [UInt8]("Hello, World!".utf8)
        let stream = InputByteStream(helloBytes)
        let bytes = try stream.readUntilEnd()
        expect(bytes == helloBytes)
    }

    func testUntilEndAsString() throws {
        let helloString = "Hello, World!"
        let helloBytes = [UInt8](helloString.utf8)
        let stream = InputByteStream(helloBytes)
        let string = try stream.readUntilEnd(as: String.self)
        expect(string == helloString)
    }

    func testReadLine() throws {
        let lines = "Hello, World!\r\nHello, World!\r\n"
        let stream = InputByteStream([UInt8](lines.utf8))
        expect(try stream.readLine() == "Hello, World!")
        expect(try stream.readLine() == "Hello, World!")
        expect(try stream.readLine() == nil)
    }
}
