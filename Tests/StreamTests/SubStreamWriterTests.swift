import Test
@testable import Stream

class SubStreamWriterTests: TestCase {
    func testSizedBy() throws {
        let stream = OutputByteStream()
        try stream.withSubStreamWriter(sizedBy: UInt16.self) { stream in
            return try stream.write("Hello, World!")
        }
        expect(stream.bytes[..<2] == [0x00, 0x0D])
        expect(stream.bytes[2...] == [UInt8]("Hello, World!".utf8)[...])
    }

    func testSizedByIncludingHeader() throws {
        let stream = OutputByteStream()
        try stream.withSubStreamWriter(
            sizedBy: UInt16.self,
            includingHeader: true)
        { stream in
            return try stream.write("Hello, World!")
        }
        expect(stream.bytes[..<2] == [0x00, 0x0F])
        expect(stream.bytes[2...] == [UInt8]("Hello, World!".utf8)[...])
    }
}
