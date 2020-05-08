import Test
@testable import Stream

class BufferedStreamWriterTests: TestCase {
    func testWriteByte() throws {
        let stream = OutputByteStream()
        let output = BufferedOutputStream(baseStream: stream, capacity: 5)

        try output.write(UInt8(42))
        try output.flush()

        expect(stream.bytes == [42])
    }
}
