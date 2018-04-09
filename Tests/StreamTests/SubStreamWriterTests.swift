import Test
@testable import Stream

class SubStreamWriterTests: TestCase {
    func testSizedBy() {
        scope {
            let stream = OutputByteStream()
            try stream.withSubStream(sizedBy: UInt16.self) { stream in
                return try stream.write("Hello, World!")
            }
            assertEqual(stream.bytes[..<2], [0x00, 0x0D])
            assertEqual(stream.bytes[2...], [UInt8]("Hello, World!".utf8)[...])
        }
    }
}
