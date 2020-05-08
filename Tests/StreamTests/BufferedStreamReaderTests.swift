import Test
@testable import Stream

class BufferedStreamReaderTests: TestCase {
    class TestStream: InputStream {
        var limit: Int?
        var counter: UInt8 = 0

        init(byteLimit limit: Int? = nil) {
            self.limit = limit
        }

        func read(
            to buffer: UnsafeMutableRawPointer,
            byteCount: Int
        ) throws -> Int {
            var byteCount = byteCount
            if let limit = limit {
                byteCount = min(limit, byteCount)
                self.limit = limit - byteCount
            }
            counter = counter &+ 1
            let buffer = UnsafeMutableRawBufferPointer(
                start: buffer,
                count: byteCount)
            for i in 0..<byteCount {
                buffer[i] = counter
            }
            return byteCount
        }
    }

    func testRead() throws {
        let stream = BufferedInputStream(
            baseStream: TestStream(),
            capacity: 1)
        expect(stream.expandable == true)
        expect(stream.allocated == 1)

        var buffer = try stream.read(count: 10)
        expect([UInt8](buffer) == [UInt8](repeating: 1, count: 10))
        expect(stream.readPosition == stream.storage + 10)
        // allocated(1) < requested,
        // so we reserve requested(10) * 2
        expect(stream.writePosition == stream.storage + 20)

        // stil have buffered data
        buffer = try stream.read(count: 10)
        expect([UInt8](buffer) == [UInt8](repeating: 1, count: 10))
        expect(stream.readPosition == stream.storage)
        expect(stream.writePosition == stream.storage)

        // buffer is empty so another read
        // from the source stream initiated
        buffer = try stream.read(count: 5)
        expect([UInt8](buffer) == [UInt8](repeating: 2, count: 5))
        expect(stream.readPosition == stream.storage + 5)
        expect(stream.writePosition == stream.storage + 20)

        // stil have 15 bytes
        // reallocate x2 because the content is > capacity / 2
        buffer = try stream.read(count: 20)
        expect(
            [UInt8](buffer)
            ==
            [UInt8](repeating: 2, count: 15)
            +
            [UInt8](repeating: 3, count: 5))
        expect(stream.readPosition == stream.storage + 20)
        expect(stream.writePosition == stream.storage + 40)

        buffer = try stream.read(count: 10)
        expect([UInt8](buffer) == [UInt8](repeating: 3, count: 10))
        expect(stream.readPosition == stream.storage + 30)
        expect(stream.writePosition == stream.storage + 40)
        expect(stream.allocated == 40)

        // shift << the content because it's < capacity / 2
        buffer = try stream.read(count: 20)
        expect(
            [UInt8](buffer)
            ==
            [UInt8](repeating: 3, count: 10)
            +
            [UInt8](repeating: 4, count: 10))
        expect(stream.readPosition == stream.storage + 20)
        expect(stream.writePosition == stream.storage + 40)
        expect(stream.allocated == 40)
    }

    func testReadReservingCapacity() throws {
        let stream = BufferedInputStream(
            baseStream: TestStream(),
            capacity: 10)
        expect(stream.expandable == true)
        expect(stream.allocated == 10)

        var buffer = try stream.read(count: 10)
        expect([UInt8](buffer) == [UInt8](repeating: 1, count: 10))
        expect(stream.readPosition == stream.storage)
        expect(stream.writePosition == stream.storage)

        buffer = try stream.read(count: 10)
        expect([UInt8](buffer) == [UInt8](repeating: 2, count: 10))
        expect(stream.readPosition == stream.storage)
        expect(stream.writePosition == stream.storage)
    }

    func testReadFixedCapacity() throws {
        let stream = BufferedInputStream(
            baseStream: TestStream(),
            capacity: 10,
            expandable: false)
        expect(stream.expandable == false)
        expect(stream.allocated == 10)

        var buffer = try stream.read(count: 10)
        expect([UInt8](buffer) == [UInt8](repeating: 1, count: 10))
        expect(stream.readPosition == stream.storage)
        expect(stream.writePosition == stream.storage)

        expect(throws: StreamError.notEnoughSpace) {
            try stream.read(count: 11)
        }

        expect(stream.readPosition == stream.storage)
        expect(stream.writePosition == stream.storage)

        buffer = try stream.read(count: 2)
        expect([UInt8](buffer) == [UInt8](repeating: 2, count: 2))
        expect(stream.readPosition == stream.storage + 2)
        expect(stream.writePosition == stream.storage + 10)

        // shift the rest and fill with another read
        buffer = try stream.read(count: 9)
        expect([UInt8](buffer) == [UInt8](repeating: 2, count: 8) + [3])
        expect(stream.readPosition == stream.storage + 9)
        expect(stream.writePosition == stream.storage + 10)
    }

    func testReadByte() {
        let stream = BufferedInputStream(
            baseStream: TestStream(byteLimit: 4),
            capacity: 2)

        expect(try stream.read(UInt8.self) == 1)
        expect(try stream.read(UInt8.self) == 1)
        expect(try stream.read(UInt8.self) == 2)
        expect(try stream.read(UInt8.self) == 2)

        expect(throws: StreamError.insufficientData) {
            try stream.read(UInt8.self)
        }
    }

    func testReadWhile() throws {
        let stream = BufferedInputStream(
            baseStream: TestStream(),
            capacity: 5)
        expect(stream.expandable == true)
        expect(stream.allocated == 5)

        let buffer = try stream.read(while: { $0 != 3 })
        expect(
            [UInt8](buffer)
            ==
            [UInt8](repeating: 1, count: 5)
            +
            [UInt8](repeating: 2, count: 7))
        expect(stream.readPosition == stream.storage + 12)
        expect(stream.writePosition == stream.storage + 26)
    }

    func testReadWhileUntilEnd() throws {
        let stream = BufferedInputStream(
            baseStream: TestStream(byteLimit: 5),
            capacity: 5)

        expect(throws: StreamError.insufficientData) {
            try stream.read(mode: .strict, while: { $0 == 1 })
        }
        // NOTE: does not consume bytes on error
        expect(stream.buffered == 5)

        _ = try stream.read(mode: .untilEnd, while: { $0 == 1 })
    }

    func testReadUntil() throws {
        let stream = BufferedInputStream(
            baseStream: TestStream(),
            capacity: 5)
        expect(stream.expandable == true)
        expect(stream.allocated == 5)

        try stream.read(until: 3) { buffer in
            let expected =
                [UInt8](repeating: 1, count: 5)
                +
                [UInt8](repeating: 2, count: 7)
            expect([UInt8](buffer) == expected)
        }
        expect(stream.readPosition == stream.storage + 12)
        expect(stream.writePosition == stream.storage + 26)
    }

    func testPeek() {
        let stream = BufferedInputStream(
            baseStream: TestStream(byteLimit: 10),
            capacity: 10,
            expandable: false)
        expect(try stream.feed() == true)
        expect(stream.readPosition == stream.storage)
        expect(stream.writePosition == stream.storage + 10)

        expect(throws: StreamError.notEnoughSpace) {
            try stream.cache(count: 15)
        }

        expect(try stream.cache(count: 5) == true)
        expect(try stream.next(is: [UInt8](repeating: 1, count: 5)))
        expect(stream.readPosition == stream.storage)
        expect(stream.writePosition == stream.storage + 10)

        expect(try stream.read(count: 10).count == 10)
        expect(try stream.cache(count: 5) == false)
    }

    func testConsume() throws {
        let stream = BufferedInputStream(
            baseStream: TestStream(),
            capacity: 10)
        expect(stream.readPosition == stream.storage)
        expect(stream.writePosition == stream.storage)

        try stream.consume(count: 5)

        expect(stream.readPosition == stream.storage + 5)
        expect(stream.writePosition == stream.storage + 10)

        try stream.consume(count: 5)

        expect(stream.readPosition == stream.storage)
        expect(stream.writePosition == stream.storage)

        let buffer = try stream.read(count: 5)
        expect([UInt8](buffer) == [UInt8](repeating: 2, count: 5))
        expect(stream.readPosition == stream.storage + 5)
        expect(stream.writePosition == stream.storage + 10)
    }

    func testConsumeNotExpandable() throws {
        let stream = BufferedInputStream(
            baseStream: TestStream(),
            capacity: 10,
            expandable: false)
        expect(stream.readPosition == stream.storage)
        expect(stream.writePosition == stream.storage)
        expect(stream.expandable == false)
        expect(stream.allocated == 10)

        try stream.consume(count: 15)

        expect(stream.readPosition == stream.storage + 5)
        expect(stream.writePosition == stream.storage + 10)
        expect(stream.expandable == false)
        expect(stream.allocated == 10)

        let buffer = try stream.read(count: 5)
        expect([UInt8](buffer) == [UInt8](repeating: 2, count: 5))
        expect(stream.readPosition == stream.storage)
        expect(stream.writePosition == stream.storage)
    }

    func testConsumeByte() {
        let stream = BufferedInputStream(baseStream: TestStream(byteLimit: 2))
        expect(stream.buffered == 0)

        expect(try stream.consume(UInt8(1)) == true)
        expect(stream.buffered == 1)

        expect(try stream.consume(UInt8(2)) == false)
        expect(stream.buffered == 1)

        expect(try stream.consume(UInt8(1)) == true)
        expect(stream.buffered == 0)

        expect(throws: StreamError.insufficientData) {
            try stream.consume(1)
        }
    }

    func testConsumeWhile() throws {
        let stream = BufferedInputStream(
            baseStream: TestStream(),
            capacity: 2)
        expect(stream.readPosition == stream.storage)
        expect(stream.writePosition == stream.storage)
        expect(stream.allocated == 2)
        expect(stream.buffered == 0)

        try stream.consume(while: { $0 == 1 || $0 == 2 })

        expect(stream.readPosition == stream.storage)
        expect(stream.writePosition == stream.storage + 2)
        expect(stream.allocated == 2)
        expect(stream.buffered == 2)

        let buffer = try stream.read(count: 10)
        expect(stream.allocated == 24)
        expect(stream.buffered == 14)

        expect(
            [UInt8](buffer)
            ==
            [UInt8](repeating: 3, count: 2)
            +
            [UInt8](repeating: 4, count: 8))
        expect(stream.readPosition == stream.storage + 10)
        expect(stream.writePosition == stream.storage + 24)
    }

    func testConsumeUntil() throws {
        let stream = BufferedInputStream(
            baseStream: TestStream(),
            capacity: 2)
        expect(stream.readPosition == stream.storage)
        expect(stream.writePosition == stream.storage)
        expect(stream.allocated == 2)
        expect(stream.buffered == 0)

        try stream.consume(until: 3)

        expect(stream.readPosition == stream.storage)
        expect(stream.writePosition == stream.storage + 2)
        expect(stream.allocated == 2)
        expect(stream.buffered == 2)

        let buffer = try stream.read(count: 10)
        expect(stream.allocated == 24)
        expect(stream.buffered == 14)

        expect(
            [UInt8](buffer)
            ==
            [UInt8](repeating: 3, count: 2)
            +
            [UInt8](repeating: 4, count: 8))
        expect(stream.readPosition == stream.storage + 10)
        expect(stream.writePosition == stream.storage + 24)
    }

    func testConsumeEmpty() {
        let stream = BufferedInputStream(baseStream: InputByteStream([]))
        expect(throws: StreamError.insufficientData) {
            try stream.consume(count: 1)
        }
    }

    func testFeedLessThanReadCount() throws {
        let stream = BufferedInputStream(
            baseStream: TestStream(byteLimit: 20),
            capacity: 10)
        expect(stream.readPosition == stream.storage)
        expect(stream.writePosition == stream.storage)

        let buffer = try stream.read(count: 20)
        expect([UInt8](buffer) == [UInt8](repeating: 1, count: 20))
    }

    func testAdvancePositionBeforeCallback() throws {
        let stream = BufferedInputStream(
            baseStream: InputByteStream([0,1,2,3,4,5,6,7,8,9]))
        try stream.readUntilEnd { bytes in
            expect(stream.readPosition == stream.writePosition)
        }
    }

    func testReadLine() {
        let stream = BufferedInputStream(
            baseStream: InputByteStream([UInt8]("line1\r\nline2\n".utf8)))
        expect(try stream.readLine() == "line1")
        expect(try stream.readLine() == "line2")
    }
}
