import Test
@testable import Stream

class BufferedStreamTests: TestCase {
    class TestInputStreamSequence: InputStream {
        func read(
            to buffer: UnsafeMutableRawPointer,
            byteCount: Int
        ) throws -> Int {
            let buffer = UnsafeMutableRawBufferPointer(
                start: buffer,
                count: byteCount)
            for i in 0..<byteCount {
                buffer[i] = UInt8(truncatingIfNeeded: i)
            }
            return byteCount
        }
    }

    func testBufferedInputStream() {
        let baseStream = TestInputStreamSequence()
        var stream = BufferedInputStream(baseStream: baseStream, capacity: 10)
        assertEqual(stream.allocated, 10)
        assertEqual(stream.buffered, 0)

        func read(count: Int) -> [UInt8] {
            var buffer = [UInt8](repeating: 0, count: count)
            assertEqual(try stream.read(to: &buffer, byteCount: count), count)
            return buffer
        }

        assertEqual(read(count: 5), [0,1,2,3,4])
        assertEqual(stream.buffered, 5)
        assertEqual(read(count: 2), [5,6])
        assertEqual(stream.buffered, 3)
        assertEqual(read(count: 13), [7,8,9,0,1,2,3,4,5,6,7,8,9])
        assertEqual(stream.buffered, 0)

        assertEqual(read(count: 10), [0,1,2,3,4,5,6,7,8,9])
        assertEqual(stream.buffered, 0)

        assertEqual(read(count: 13), [0,1,2,3,4,5,6,7,8,9,10,11,12])
        assertEqual(stream.buffered, 0)

        assertEqual(read(count: 9), [0,1,2,3,4,5,6,7,8])
        assertEqual(stream.buffered, 1)
        assertEqual(read(count: 13), [9,0,1,2,3,4,5,6,7,8,9,10,11])
        assertEqual(stream.buffered, 0)
        // test if stream resets if drained
        stream.clear()
        assertEqual(stream.buffered, 0)
        _ = read(count: 1)
        assertEqual(stream.buffered, 9)
        _ = read(count: 9)
        assertEqual(stream.buffered, 0)
        assertEqual(stream.readPosition, stream.storage)
        assertEqual(stream.writePosition, stream.storage)
    }

    func testBufferedOutputStream() {
        let testStream = TestStream()
        let stream = BufferedOutputStream(baseStream: testStream, capacity: 10)
        assertEqual(stream.allocated, 10)
        assertEqual(stream.buffered, 0)

        assertEqual(try stream.write(from: [0,1,2,3,4]), 5)
        assertEqual(stream.buffered, 5)
        assertEqual(try stream.write(from: [5,6]), 2)
        assertEqual(stream.buffered, 7)
        assertEqual(try stream.write(from: [7,8,9]), 3)
        assertEqual(stream.buffered, 0)

        assertEqual(testStream.storage, [0,1,2,3,4,5,6,7,8,9])
        testStream.storage = []

        assertEqual(try stream.write(from: [0,1,2,3,4,5,6,7,8]), 9)
        assertEqual(stream.buffered, 9)
        assertEqual(try stream.write(from: [9,0,1,2,3,4,5,6,7,8,9,10,11]), 13)
        assertEqual(stream.buffered, 0)

        assertEqual(testStream.storage, [
            0,1,2,3,4,5,6,7,8,
            9,0,1,2,3,4,5,6,7,8,9,10,11
        ])
        testStream.storage = []

        assertEqual(try stream.write(from: [0,1,2,3,4,5,6,7,8]), 9)
        assertEqual(stream.buffered, 9)
        assertEqual(try stream.write(from: [9,0,1]), 3)
        assertEqual(stream.buffered, 2)

        assertEqual(testStream.storage, [0,1,2,3,4,5,6,7,8,9])
        testStream.storage = []

        assertNoThrow(try stream.flush())
        assertEqual(stream.buffered, 0)

        assertEqual(testStream.storage, [0,1])
    }

    func testBufferedStream() {
        var stream = BufferedStream(baseStream: TestStream(), capacity: 10)

        func read(count: Int) -> [UInt8] {
            var buffer = [UInt8](repeating: 0, count: count)
            guard let count = try? stream.read(to: &buffer) else {
                fail()
                return []
            }
            return [UInt8](buffer.prefix(upTo: count))
        }

        assertEqual(try stream.write(from: [0,1,2,3,4]), 5)
        assertEqual(stream.outputStream.buffered, 5)

        assertEqual(read(count: 5), [])
        assertEqual(stream.inputStream.buffered, 0)
        assertNoThrow(try stream.flush())
        assertEqual(stream.outputStream.buffered, 0)
        assertEqual(read(count: 5), [0,1,2,3,4])
        assertEqual(stream.inputStream.buffered, 0)
    }

    func testBufferedInputStreamDefaultCapacity() {
        let stream = BufferedInputStream(baseStream: TestStream())
        assertEqual(stream.allocated, 256)
        assertEqual(stream.buffered, 0)
    }

    func testBufferedOutputStreamDefaultCapacity() {
        let stream = BufferedOutputStream(baseStream: TestStream())
        assertEqual(stream.allocated, 256)
        assertEqual(stream.buffered, 0)
    }

    func testBufferedStreamDefaultCapacity() {
        let stream = BufferedStream(baseStream: TestStream())
        assertEqual(stream.inputStream.allocated, 4096)
        assertEqual(stream.inputStream.buffered, 0)
        assertEqual(stream.outputStream.allocated, 4096)
        assertEqual(stream.outputStream.buffered, 0)
    }
}
