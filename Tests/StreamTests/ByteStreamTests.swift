import Test
@testable import Stream

class ByteStreamTests: TestCase {
    func testInputStream() {
        let inputStream  = InputByteStream([])
        var buffer = [UInt8]()
        assertNoThrow(try inputStream.read(to: &buffer, byteCount: 0))
    }

    func testOutputStream() {
        let outputStream  = OutputByteStream()
        let bytes = [UInt8]()
        assertNoThrow(try outputStream.write(from: bytes, byteCount: 0))
    }

    func testNumeric() {
        scope {
            let outputStream  = OutputByteStream()

            try outputStream.write(Int(-1))
            try outputStream.write(Int8(-2))
            try outputStream.write(Int16(-3))
            try outputStream.write(Int32(-4))
            try outputStream.write(Int64(-5))
            try outputStream.write(UInt(1))
            try outputStream.write(UInt8(2))
            try outputStream.write(UInt16(3))
            try outputStream.write(UInt32(4))
            try outputStream.write(UInt64(5))

            let inputStream  = InputByteStream(outputStream.bytes)

            assertEqual(try inputStream.read(Int.self), -1)
            assertEqual(try inputStream.read(Int8.self), -2)
            assertEqual(try inputStream.read(Int16.self), -3)
            assertEqual(try inputStream.read(Int32.self), -4)
            assertEqual(try inputStream.read(Int64.self), -5)
            assertEqual(try inputStream.read(UInt.self), 1)
            assertEqual(try inputStream.read(UInt8.self), 2)
            assertEqual(try inputStream.read(UInt16.self), 3)
            assertEqual(try inputStream.read(UInt32.self), 4)
            assertEqual(try inputStream.read(UInt64.self), 5)
        }
    }

    func testCopyBytes() {
        scope {
            let input = InputByteStream([0,1,2,3,4,5,6,7,8,9])
            let output = OutputByteStream()

            let copied = try output.copyBytes(from: input, bufferSize: 3)
            assertEqual(copied, 10)
            assertEqual(output.bytes, [0,1,2,3,4,5,6,7,8,9])
        }
    }

    func testAdvancePositionBeforeCallback() {
        scope {
            let input = InputByteStream([0,1,2,3,4,5,6,7,8,9])
            try input.readUntilEnd { bytes in
                assertEqual(input.position, input.bytes.count)
            }
        }
    }
}
