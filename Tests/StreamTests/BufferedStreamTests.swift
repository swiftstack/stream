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
        let stream = BufferedInputStream(baseStream: baseStream, capacity: 10)
        expect(stream.allocated == 10)
        expect(stream.buffered == 0)

        func read(count: Int) -> [UInt8] {
            var buffer = [UInt8](repeating: 0, count: count)
            expect(try stream.read(to: &buffer, byteCount: count) == count)
            return buffer
        }

        expect(read(count: 5) == [0,1,2,3,4])
        expect(stream.buffered == 5)
        expect(read(count: 2) == [5,6])
        expect(stream.buffered == 3)
        expect(read(count: 13) == [7,8,9,0,1,2,3,4,5,6,7,8,9])
        expect(stream.buffered == 0)

        expect(read(count: 10) == [0,1,2,3,4,5,6,7,8,9])
        expect(stream.buffered == 0)

        expect(read(count: 13) == [0,1,2,3,4,5,6,7,8,9,10,11,12])
        expect(stream.buffered == 0)

        expect(read(count: 9) == [0,1,2,3,4,5,6,7,8])
        expect(stream.buffered == 1)
        expect(read(count: 13) == [9,0,1,2,3,4,5,6,7,8,9,10,11])
        expect(stream.buffered == 0)
        // test if stream resets if drained
        stream.clear()
        expect(stream.buffered == 0)
        _ = read(count: 1)
        expect(stream.buffered == 9)
        _ = read(count: 9)
        expect(stream.buffered == 0)
        expect(stream.readPosition == stream.storage)
        expect(stream.writePosition == stream.storage)
    }

    func testBufferedOutputStream() {
        let testStream = TestStream()
        let stream = BufferedOutputStream(baseStream: testStream, capacity: 10)
        expect(stream.allocated == 10)
        expect(stream.buffered == 0)

        expect(try stream.write(from: [0,1,2,3,4]) == 5)
        expect(stream.buffered == 5)
        expect(try stream.write(from: [5,6]) == 2)
        expect(stream.buffered == 7)
        expect(try stream.write(from: [7,8,9]) == 3)
        expect(stream.buffered == 0)

        expect(testStream.storage == [0,1,2,3,4,5,6,7,8,9])
        testStream.storage = []

        expect(try stream.write(from: [0,1,2,3,4,5,6,7,8]) == 9)
        expect(stream.buffered == 9)
        expect(try stream.write(from: [9,0,1,2,3,4,5,6,7,8,9,10,11]) == 13)
        expect(stream.buffered == 0)

        expect(testStream.storage == [
            0,1,2,3,4,5,6,7,8,
            9,0,1,2,3,4,5,6,7,8,9,10,11
        ])
        testStream.storage = []

        expect(try stream.write(from: [0,1,2,3,4,5,6,7,8]) == 9)
        expect(stream.buffered == 9)
        expect(try stream.write(from: [9,0,1]) == 3)
        expect(stream.buffered == 2)

        expect(testStream.storage == [0,1,2,3,4,5,6,7,8,9])
        testStream.storage = []

        expect(try stream.flush() == ())
        expect(stream.buffered == 0)

        expect(testStream.storage == [0,1])
    }

    func testBufferedStream() {
        let stream = BufferedStream(baseStream: TestStream(), capacity: 10)

        func read(count: Int) -> [UInt8] {
            var buffer = [UInt8](repeating: 0, count: count)
            guard let count = try? stream.read(to: &buffer) else {
                fail()
                return []
            }
            return [UInt8](buffer.prefix(upTo: count))
        }

        expect(try stream.write(from: [0,1,2,3,4]) == 5)
        expect(stream.outputStream.buffered == 5)

        expect(read(count: 5) == [])
        expect(stream.inputStream.buffered == 0)
        expect(try stream.flush() == ())
        expect(stream.outputStream.buffered == 0)
        expect(read(count: 5) == [0,1,2,3,4])
        expect(stream.inputStream.buffered == 0)
    }

    func testBufferedInputStreamDefaultCapacity() {
        let stream = BufferedInputStream(baseStream: TestStream())
        expect(stream.allocated == 256)
        expect(stream.buffered == 0)
    }

    func testBufferedOutputStreamDefaultCapacity() {
        let stream = BufferedOutputStream(baseStream: TestStream())
        expect(stream.allocated == 256)
        expect(stream.buffered == 0)
    }

    func testBufferedStreamDefaultCapacity() {
        let stream = BufferedStream(baseStream: TestStream())
        expect(stream.inputStream.allocated == 4096)
        expect(stream.inputStream.buffered == 0)
        expect(stream.outputStream.allocated == 4096)
        expect(stream.outputStream.buffered == 0)
    }
}
