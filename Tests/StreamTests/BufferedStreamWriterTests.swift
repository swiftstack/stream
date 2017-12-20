import Test
@testable import Stream

class BufferedStreamWriterTests: TestCase {
    func testWriteByte() {
        let stream = OutputByteStream()
        let output = BufferedOutputStream(baseStream: stream, capacity: 5)

        assertNoThrow(try output.write(UInt8(42)))
        assertNoThrow(try output.flush())

        assertEqual(stream.bytes, [42])
    }
}
