import Test
@testable import Stream

class StreamTests: TestCase {
    func testStream() throws {
        let testStream  = TestStream()
        let stream = testStream as Stream
        var bytes = [UInt8]()
        _ = try stream.read(to: &bytes, byteCount: 0)
        _ = try stream.write(from: bytes, byteCount: 0)
    }

    func testInputStream() throws {
        let testStream  = TestStream()
        let inputStream = testStream as InputStream
        var buffer = [UInt8]()
        _ = try inputStream.read(to: &buffer, byteCount: 0)
    }

    func testOutputStream() throws {
        let testStream  = TestStream()
        let outputStream = testStream as OutputStream
        let bytes = [UInt8]()
        _ = try outputStream.write(from: bytes, byteCount: 0)
    }

    func testCopyBytes() throws {
        let input = TestStream()
        let output = TestStream()

        expect(try input.write(from: [0,1,2,3,4,5,6,7,8,9]) == 10)
        let copied = try output.copyBytes(from: input, bufferSize: 3)
        expect(copied == 10)
        expect(output.storage == [0,1,2,3,4,5,6,7,8,9])
    }
}
