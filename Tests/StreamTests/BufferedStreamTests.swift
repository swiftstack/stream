import Test
@testable import Stream

class BufferedStreamTests: TestCase {
    class TestInputStreamSequence: InputStream {
        func read(
            to buffer: UnsafeMutableRawPointer, byteCount: Int
        ) throws -> Int {
            for i in 0..<byteCount {
                buffer.advanced(by: i)
                    .assumingMemoryBound(to: UInt8.self)
                    .pointee = UInt8(truncatingIfNeeded: i)
            }
            return byteCount
        }
    }

    func testBufferedInputStream() {
        let baseStream = TestInputStreamSequence()
        var stream = BufferedInputStream(baseStream: baseStream, capacity: 10)
        assertEqual(stream.allocated, 10)
        assertEqual(stream.count, 0)

        func read(count: Int) -> [UInt8] {
            var buffer = [UInt8](repeating: 0, count: count)
            assertEqual(try stream.read(to: &buffer), count)
            return buffer
        }

        assertEqual(read(count: 5), [0,1,2,3,4])
        assertEqual(stream.count, 5)
        assertEqual(read(count: 2), [5,6])
        assertEqual(stream.count, 3)
        assertEqual(read(count: 13), [7,8,9,0,1,2,3,4,5,6,7,8,9])
        assertEqual(stream.count, 0)

        assertEqual(read(count: 10), [0,1,2,3,4,5,6,7,8,9])
        assertEqual(stream.count, 0)

        assertEqual(read(count: 13), [0,1,2,3,4,5,6,7,8,9,10,11,12])
        assertEqual(stream.count, 0)

        assertEqual(read(count: 9), [0,1,2,3,4,5,6,7,8])
        assertEqual(stream.count, 1)
        assertEqual(read(count: 13), [9,0,1,2,3,4,5,6,7,8,9,10,11])
        assertEqual(stream.count, 0)
    }

    func testBufferedOutputStream() {
        let testStream = TestStream()
        let stream = BufferedOutputStream(baseStream: testStream, capacity: 10)
        assertEqual(stream.allocated, 10)
        assertEqual(stream.buffered, 0)

        assertEqual(try stream.write([0,1,2,3,4]), 5)
        assertEqual(stream.buffered, 5)
        assertEqual(try stream.write([5,6]), 2)
        assertEqual(stream.buffered, 7)
        assertEqual(try stream.write([7,8,9]), 3)
        assertEqual(stream.buffered, 0)

        assertEqual(testStream.storage, [0,1,2,3,4,5,6,7,8,9])
        testStream.storage = []

        assertEqual(try stream.write([0,1,2,3,4,5,6,7,8]), 9)
        assertEqual(stream.buffered, 9)
        assertEqual(try stream.write([9,0,1,2,3,4,5,6,7,8,9,10,11]), 13)
        assertEqual(stream.buffered, 0)

        assertEqual(testStream.storage, [
            0,1,2,3,4,5,6,7,8,
            9,0,1,2,3,4,5,6,7,8,9,10,11
        ])
        testStream.storage = []

        assertEqual(try stream.write([0,1,2,3,4,5,6,7,8]), 9)
        assertEqual(stream.buffered, 9)
        assertEqual(try stream.write([9,0,1]), 3)
        assertEqual(stream.buffered, 2)

        assertEqual(testStream.storage, [0,1,2,3,4,5,6,7,8,9])
        testStream.storage = []

        assertEqual(try stream.flush(), 2)
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

        assertEqual(try stream.write([0,1,2,3,4]), 5)
        assertEqual(stream.outputStream.buffered, 5)

        assertEqual(read(count: 5), [])
        assertEqual(stream.inputStream.count, 0)
        assertNoThrow(try stream.flush())
        assertEqual(stream.outputStream.buffered, 0)
        assertEqual(read(count: 5), [0,1,2,3,4])
        assertEqual(stream.inputStream.count, 0)
    }

    func testBufferedInputStreamDefaultCapacity() {
        let stream = BufferedInputStream(baseStream: TestStream())
        assertEqual(stream.allocated, 0)
        assertEqual(stream.count, 0)
    }

    func testBufferedOutputStreamDefaultCapacity() {
        let stream = BufferedOutputStream(baseStream: TestStream())
        assertEqual(stream.allocated, 4096)
        assertEqual(stream.buffered, 0)
    }

    func testBufferedStreamDefaultCapacity() {
        let stream = BufferedStream(baseStream: TestStream())
        assertEqual(stream.inputStream.allocated, 4096)
        assertEqual(stream.inputStream.count, 0)
        assertEqual(stream.outputStream.allocated, 4096)
        assertEqual(stream.outputStream.buffered, 0)
    }
}