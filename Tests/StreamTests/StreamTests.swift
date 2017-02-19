import Test
@testable import Stream

class StreamTests: TestCase {
    class TestStream: Stream {
        func read(to buffer: UnsafeMutableRawPointer, count: Int) throws -> Int {
            return count
        }

        func write(from buffer: UnsafeRawPointer, count: Int) throws -> Int {
            return count
        }
    }

    class TestInputStream: InputStream {
        func read(to buffer: UnsafeMutableRawPointer, count: Int) throws -> Int {
            return count
        }
    }

    class TestOutputStream: OutputStream {
        func write(from buffer: UnsafeRawPointer, count: Int) throws -> Int {
            return count
        }
    }

    func testStream() {
        let testStream  = TestStream()
        let stream = testStream as Stream
        var buffer = [UInt8]()
        assertNoThrow(try stream.read(to: &buffer, count: 0))
        assertNoThrow(try stream.write(from: buffer, count: 0))
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
        let buffer = [UInt8]()
        assertNoThrow(try outputStream.write(from: buffer, count: 0))
    }

    func testStreamType() {
        let type = String(describing: type(of: Stream.self))
        assertEqual(type, "Stream.Protocol")
    }

    func testInputStreamType() {
        let type = String(describing: type(of: InputStream.self))
        assertEqual(type, "InputStream.Protocol")
    }

    func testOutputStreamType() {
        let type = String(describing: type(of: OutputStream.self))
        assertEqual(type, "OutputStream.Protocol")
    }
}
