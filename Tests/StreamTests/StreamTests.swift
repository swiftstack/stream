import Test
@testable import Stream

class StreamTests: TestCase {
    func testStream() {
        let testStream  = TestStream()
        let stream = testStream as Stream
        var bytes = [UInt8]()
        assertNoThrow(try stream.read(to: &bytes, byteCount: 0))
        assertNoThrow(try stream.write(from: bytes, byteCount: 0))
    }

    func testInputStream() {
        let testStream  = TestStream()
        let inputStream = testStream as InputStream
        var buffer = [UInt8]()
        assertNoThrow(try inputStream.read(to: &buffer, byteCount: 0))
    }

    func testOutputStream() {
        let testStream  = TestStream()
        let outputStream = testStream as OutputStream
        let bytes = [UInt8]()
        assertNoThrow(try outputStream.write(from: bytes, byteCount: 0))
    }

    func testCopyBytes() {
        scope {
            let input = TestStream()
            let output = TestStream()

            assertEqual(try input.write(from: [0,1,2,3,4,5,6,7,8,9]), 10)
            let copied = try output.copyBytes(from: input, bufferSize: 3)
            assertEqual(copied, 10)
            assertEqual(output.storage, [0,1,2,3,4,5,6,7,8,9])
        }
    }
}
