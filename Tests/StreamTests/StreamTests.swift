import Test
@testable import Stream

class StreamTests: TestCase {
    func testStream() {
        let testStream  = TestStream()
        let stream = testStream as Stream
        var bytes = [UInt8]()
        assertNoThrow(try stream.read(to: &bytes, byteCount: 0))
        assertNoThrow(try stream.write(bytes, byteCount: 0))
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
        assertNoThrow(try outputStream.write(bytes, byteCount: 0))
    }

    func testNumeric() {
        let stream  = TestStream()
        do {
            try stream.write(Int(-1))
            try stream.write(Int8(-2))
            try stream.write(Int16(-3))
            try stream.write(Int32(-4))
            try stream.write(Int64(-5))
            try stream.write(UInt(1))
            try stream.write(UInt8(2))
            try stream.write(UInt16(3))
            try stream.write(UInt32(4))
            try stream.write(UInt64(5))

            assertEqual(try stream.read(Int.self), -1)
            assertEqual(try stream.read(Int8.self), -2)
            assertEqual(try stream.read(Int16.self), -3)
            assertEqual(try stream.read(Int32.self), -4)
            assertEqual(try stream.read(Int64.self), -5)
            assertEqual(try stream.read(UInt.self), 1)
            assertEqual(try stream.read(UInt8.self), 2)
            assertEqual(try stream.read(UInt16.self), 3)
            assertEqual(try stream.read(UInt32.self), 4)
            assertEqual(try stream.read(UInt64.self), 5)
        } catch {
            fail(String(describing: error))
        }
    }

    func testCopyBytes() {
        do {
            var input = TestStream()
            let output = TestStream()

            assertEqual(try input.write([0,1,2,3,4,5,6,7,8,9]), 10)
            let copied = try output.copyBytes(from: &input, bufferSize: 3)
            assertEqual(copied, 10)
            assertEqual(output.storage, [0,1,2,3,4,5,6,7,8,9])
        } catch {
            fail(String(describing: error))
        }
    }
}
