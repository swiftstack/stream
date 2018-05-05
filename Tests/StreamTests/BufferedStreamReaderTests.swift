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

    func testRead() {
        scope {
            let stream = BufferedInputStream(
                baseStream: TestStream(),
                capacity: 1)
            assertEqual(stream.expandable, true)
            assertEqual(stream.allocated, 1)

            var buffer = try stream.read(count: 10)
            assertEqual([UInt8](buffer), [UInt8](repeating: 1, count: 10))
            assertEqual(stream.readPosition, stream.storage + 10)
            // allocated(1) < requested,
            // so we reserve requested(10) * 2
            assertEqual(stream.writePosition, stream.storage + 20)

            // stil have buffered data
            buffer = try stream.read(count: 10)
            assertEqual([UInt8](buffer), [UInt8](repeating: 1, count: 10))
            assertEqual(stream.readPosition, stream.storage)
            assertEqual(stream.writePosition, stream.storage)

            // buffer is empty so another read
            // from the source stream initiated
            buffer = try stream.read(count: 5)
            assertEqual([UInt8](buffer), [UInt8](repeating: 2, count: 5))
            assertEqual(stream.readPosition, stream.storage + 5)
            assertEqual(stream.writePosition, stream.storage + 20)

            // stil have 15 bytes
            // reallocate x2 because the content is > capacity / 2
            buffer = try stream.read(count: 20)
            assertEqual(
                [UInt8](buffer),
                [UInt8](repeating: 2, count: 15) +
                    [UInt8](repeating: 3, count: 5))
            assertEqual(stream.readPosition, stream.storage + 20)
            assertEqual(stream.writePosition, stream.storage + 40)

            buffer = try stream.read(count: 10)
            assertEqual([UInt8](buffer), [UInt8](repeating: 3, count: 10))
            assertEqual(stream.readPosition, stream.storage + 30)
            assertEqual(stream.writePosition, stream.storage + 40)
            assertEqual(stream.allocated, 40)

            // shift << the content because it's < capacity / 2
            buffer = try stream.read(count: 20)
            assertEqual([UInt8](buffer),
                        [UInt8](repeating: 3, count: 10) +
                            [UInt8](repeating: 4, count: 10))
            assertEqual(stream.readPosition, stream.storage + 20)
            assertEqual(stream.writePosition, stream.storage + 40)
            assertEqual(stream.allocated, 40)
        }
    }

    func testReadReservingCapacity() {
        scope {
            let stream = BufferedInputStream(
                baseStream: TestStream(),
                capacity: 10)
            assertEqual(stream.expandable, true)
            assertEqual(stream.allocated, 10)

            var buffer = try stream.read(count: 10)
            assertEqual([UInt8](buffer), [UInt8](repeating: 1, count: 10))
            assertEqual(stream.readPosition, stream.storage)
            assertEqual(stream.writePosition, stream.storage)

            buffer = try stream.read(count: 10)
            assertEqual([UInt8](buffer), [UInt8](repeating: 2, count: 10))
            assertEqual(stream.readPosition, stream.storage)
            assertEqual(stream.writePosition, stream.storage)
        }
    }

    func testReadFixedCapacity() {
        scope {
            let stream = BufferedInputStream(
                baseStream: TestStream(),
                capacity: 10,
                expandable: false)
            assertEqual(stream.expandable, false)
            assertEqual(stream.allocated, 10)

            var buffer = try stream.read(count: 10)
            assertEqual([UInt8](buffer), [UInt8](repeating: 1, count: 10))
            assertEqual(stream.readPosition, stream.storage)
            assertEqual(stream.writePosition, stream.storage)

            assertThrowsError(try stream.read(count: 11)) { error in
                assertEqual(.notEnoughSpace, error as? StreamError)
            }

            assertEqual(stream.readPosition, stream.storage)
            assertEqual(stream.writePosition, stream.storage)


            buffer = try stream.read(count: 2)
            assertEqual([UInt8](buffer), [UInt8](repeating: 2, count: 2))
            assertEqual(stream.readPosition, stream.storage + 2)
            assertEqual(stream.writePosition, stream.storage + 10)

            // shift the rest and fill with another read
            buffer = try stream.read(count: 9)
            assertEqual([UInt8](buffer), [UInt8](repeating: 2, count: 8) + [3])
            assertEqual(stream.readPosition, stream.storage + 9)
            assertEqual(stream.writePosition, stream.storage + 10)
        }
    }

    func testReadByte() {
        let stream = BufferedInputStream(
            baseStream: TestStream(byteLimit: 4),
            capacity: 2)

        assertEqual(try stream.read(UInt8.self), 1)
        assertEqual(try stream.read(UInt8.self), 1)
        assertEqual(try stream.read(UInt8.self), 2)
        assertEqual(try stream.read(UInt8.self), 2)

        assertThrowsError(try stream.read(UInt8.self)) { error in
            assertEqual(error as? StreamError, .insufficientData)
        }
    }

    func testReadWhile() {
        scope {
            let stream = BufferedInputStream(
                baseStream: TestStream(),
                capacity: 5)
            assertEqual(stream.expandable, true)
            assertEqual(stream.allocated, 5)

            let buffer = try stream.read(while: { $0 != 3 })
            assertEqual([UInt8](buffer),
                        [UInt8](repeating: 1, count: 5) +
                            [UInt8](repeating: 2, count: 7))
            assertEqual(stream.readPosition, stream.storage + 12)
            assertEqual(stream.writePosition, stream.storage + 26)
        }
    }

    func testReadWhileUntilEnd() {
        let stream = BufferedInputStream(
            baseStream: TestStream(byteLimit: 5),
            capacity: 5)

        assertThrowsError(try stream.read(mode: .strict, while: { $0 == 1 }))
        { error in
            assertEqual(error as? StreamError, .insufficientData)
        }
        // NOTE: changed to not consume bytes if failed
        assertEqual(stream.buffered, 5)
        assertNoThrow(try stream.read(mode: .untilEnd, while: { $0 == 1 }))
    }

    func testReadUntil() {
        scope {
            let stream = BufferedInputStream(
                baseStream: TestStream(),
                capacity: 5)
            assertEqual(stream.expandable, true)
            assertEqual(stream.allocated, 5)

            try stream.read(until: 3) { buffer in
                let expected =
                    [UInt8](repeating: 1, count: 5) +
                        [UInt8](repeating: 2, count: 7)
                assertEqual([UInt8](buffer), expected)
            }
            assertEqual(stream.readPosition, stream.storage + 12)
            assertEqual(stream.writePosition, stream.storage + 26)
        }
    }

    func testPeek() {
        let stream = BufferedInputStream(
            baseStream: TestStream(byteLimit: 10),
            capacity: 10,
            expandable: false)
        assertTrue(try stream.feed())
        assertEqual(stream.readPosition, stream.storage)
        assertEqual(stream.writePosition, stream.storage + 10)

        assertThrowsError(try stream.cache(count: 15)) { error in
            assertEqual(.notEnoughSpace, error as? StreamError)
        }

        assertNoThrow(try stream.cache(count: 5))
        assertTrue(try stream.next(is: [UInt8](repeating: 1, count: 5)))
        assertEqual(stream.readPosition, stream.storage)
        assertEqual(stream.writePosition, stream.storage + 10)

        assertNoThrow(try stream.read(count: 10))
        assertFalse(try stream.cache(count: 5))
    }

    func testConsume() {
        scope {
            let stream = BufferedInputStream(
                baseStream: TestStream(),
                capacity: 10)
            assertEqual(stream.readPosition, stream.storage)
            assertEqual(stream.writePosition, stream.storage)

            try stream.consume(count: 5)

            assertEqual(stream.readPosition, stream.storage + 5)
            assertEqual(stream.writePosition, stream.storage + 10)

            try stream.consume(count: 5)

            assertEqual(stream.readPosition, stream.storage)
            assertEqual(stream.writePosition, stream.storage)

            let buffer = try stream.read(count: 5)
            assertEqual([UInt8](buffer), [UInt8](repeating: 2, count: 5))
            assertEqual(stream.readPosition, stream.storage + 5)
            assertEqual(stream.writePosition, stream.storage + 10)
        }
    }

    func testConsumeNotExpandable() {
        scope {
            let stream = BufferedInputStream(
                baseStream: TestStream(),
                capacity: 10,
                expandable: false)
            assertEqual(stream.readPosition, stream.storage)
            assertEqual(stream.writePosition, stream.storage)
            assertEqual(stream.expandable, false)
            assertEqual(stream.allocated, 10)

            try stream.consume(count: 15)

            assertEqual(stream.readPosition, stream.storage + 5)
            assertEqual(stream.writePosition, stream.storage + 10)
            assertEqual(stream.expandable, false)
            assertEqual(stream.allocated, 10)

            let buffer = try stream.read(count: 5)
            assertEqual([UInt8](buffer), [UInt8](repeating: 2, count: 5))
            assertEqual(stream.readPosition, stream.storage)
            assertEqual(stream.writePosition, stream.storage)
        }
    }

    func testConsumeByte() {
        let stream = BufferedInputStream(baseStream: TestStream(byteLimit: 2))
        assertEqual(stream.buffered, 0)

        assertTrue(try stream.consume(UInt8(1)))
        assertEqual(stream.buffered, 1)

        assertFalse(try stream.consume(UInt8(2)))
        assertEqual(stream.buffered, 1)

        assertTrue(try stream.consume(UInt8(1)))
        assertEqual(stream.buffered, 0)

        assertThrowsError(try stream.consume(1)) { error in
            assertEqual(error as? StreamError, .insufficientData)
        }
    }

    func testConsumeWhile() {
        scope {
            let stream = BufferedInputStream(
                baseStream: TestStream(),
                capacity: 2)
            assertEqual(stream.readPosition, stream.storage)
            assertEqual(stream.writePosition, stream.storage)
            assertEqual(stream.allocated, 2)
            assertEqual(stream.buffered, 0)

            try stream.consume(while: { $0 == 1 || $0 == 2 })

            assertEqual(stream.readPosition, stream.storage)
            assertEqual(stream.writePosition, stream.storage + 2)
            assertEqual(stream.allocated, 2)
            assertEqual(stream.buffered, 2)

            let buffer = try stream.read(count: 10)
            assertEqual(stream.allocated, 24)
            assertEqual(stream.buffered, 14)

            assertEqual([UInt8](buffer),
                        [UInt8](repeating: 3, count: 2)
                            + [UInt8](repeating: 4, count: 8))
            assertEqual(stream.readPosition, stream.storage + 10)
            assertEqual(stream.writePosition, stream.storage + 24)
        }
    }

    func testConsumeUntil() {
        scope {
            let stream = BufferedInputStream(
                baseStream: TestStream(),
                capacity: 2)
            assertEqual(stream.readPosition, stream.storage)
            assertEqual(stream.writePosition, stream.storage)
            assertEqual(stream.allocated, 2)
            assertEqual(stream.buffered, 0)

            try stream.consume(until: 3)

            assertEqual(stream.readPosition, stream.storage)
            assertEqual(stream.writePosition, stream.storage + 2)
            assertEqual(stream.allocated, 2)
            assertEqual(stream.buffered, 2)

            let buffer = try stream.read(count: 10)
            assertEqual(stream.allocated, 24)
            assertEqual(stream.buffered, 14)

            assertEqual([UInt8](buffer),
                        [UInt8](repeating: 3, count: 2)
                            + [UInt8](repeating: 4, count: 8))
            assertEqual(stream.readPosition, stream.storage + 10)
            assertEqual(stream.writePosition, stream.storage + 24)
        }
    }

    func testFeedLessThanReadCount() {
        scope {
            let stream = BufferedInputStream(
                baseStream: TestStream(byteLimit: 20),
                capacity: 10)
            assertEqual(stream.readPosition, stream.storage)
            assertEqual(stream.writePosition, stream.storage)

            let buffer = try stream.read(count: 20)
            assertEqual([UInt8](buffer), [UInt8](repeating: 1, count: 20))
        }
    }

    func testAdvancePositionBeforeCallback() {
        scope {
            let stream = BufferedInputStream(
                baseStream: InputByteStream([0,1,2,3,4,5,6,7,8,9]))
            try stream.readUntilEnd { bytes in
                assertEqual(stream.readPosition, stream.writePosition)
            }
        }
    }

    func testReadLine() {
        scope {
            let stream = BufferedInputStream(
                baseStream: InputByteStream([UInt8]("line1\r\nline2\n".utf8)))
            assertEqual(try stream.readLine(), "line1")
            assertEqual(try stream.readLine(), "line2")
        }
    }
}
