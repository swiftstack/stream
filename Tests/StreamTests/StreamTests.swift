import Test
@testable import Stream

class StreamTests: TestCase {
    class TestStream: Stream {
        func read(to buffer: UnsafeMutableRawBufferPointer) throws -> Int {
            return buffer.count
        }

        func write(_ bytes: UnsafeRawBufferPointer) throws -> Int {
            return bytes.count
        }
    }

    class TestInputStream: InputStream {
        func read(to buffer: UnsafeMutableRawBufferPointer) throws -> Int {
            return buffer.count
        }
    }

    class TestOutputStream: OutputStream {
        func write(_ bytes: UnsafeRawBufferPointer) throws -> Int {
            return bytes.count
        }
    }

    func testStream() {
        let testStream  = TestStream()
        let stream = testStream as Stream
        var bytes = [UInt8]()
        assertNoThrow(try stream.read(to: &bytes, count: 0))
        assertNoThrow(try stream.write(bytes, count: 0))
    }

    func testInputStream() {
        let testStream  = TestInputStream()
        let inputStream = testStream as InputStream
        var buffer = [UInt8]()
        assertNoThrow(try inputStream.read(to: &buffer, count: 0))
    }

    func testOutputStream() {
        let testStream  = TestOutputStream()
        let outputStream = testStream as OutputStream
        let bytes = [UInt8]()
        assertNoThrow(try outputStream.write(bytes, count: 0))
    }

    func testStreamType() {
        let protocolType = String(describing: type(of: Stream.self))
        assertEqual(protocolType, "Stream.Protocol")
    }

    func testInputStreamType() {
        let protocolType = String(describing: type(of: InputStream.self))
        assertEqual(protocolType, "InputStream.Protocol")
    }

    func testOutputStreamType() {
        let protocolType = String(describing: type(of: OutputStream.self))
        assertEqual(protocolType, "OutputStream.Protocol")
    }
}
