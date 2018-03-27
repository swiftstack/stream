import Test
@testable import Stream

class BufferedStreamReaderTests: TestCase {
    class TestStream: InputStream {
        var limit: Int?

        init(generateBytesCount limit: Int? = nil) {
            self.limit = limit
        }

        var counter: UInt8 = 0

        func read(
            to buffer: UnsafeMutableRawPointer, byteCount: Int
        ) throws -> Int {
            var byteCount = byteCount
            if let limit = limit {
                byteCount = min(limit, byteCount)
                self.limit = limit - byteCount
            }
            counter = counter &+ 1
            for i in 0..<byteCount {
                buffer.advanced(by: i)
                    .assumingMemoryBound(to: UInt8.self)
                    .pointee = counter
            }
            return byteCount
        }
    }

    func testRead() {
        do {
            let input = BufferedInputStream(
                baseStream: TestStream(),
                capacity: 1)
            assertEqual(input.expandable, true)
            assertEqual(input.allocated, 1)

            var buffer = try input.read(count: 10)
            assertEqual([UInt8](buffer), [UInt8](repeating: 1, count: 10))
            assertEqual(input.readPosition, input.storage + 10)
            // allocated(1) < requested,
            // so we reserve requested(10) * 2
            assertEqual(input.writePosition, input.storage + 20)

            // stil have buffered data
            buffer = try input.read(count: 10)
            assertEqual([UInt8](buffer), [UInt8](repeating: 1, count: 10))
            assertEqual(input.readPosition, input.storage)
            assertEqual(input.writePosition, input.storage)

            // buffer is empty so another read
            // from the source stream initiated
            buffer = try input.read(count: 5)
            assertEqual([UInt8](buffer), [UInt8](repeating: 2, count: 5))
            assertEqual(input.readPosition, input.storage + 5)
            assertEqual(input.writePosition, input.storage + 20)

            // stil have 15 bytes
            // reallocate x2 because the content is > capacity / 2
            buffer = try input.read(count: 20)
            assertEqual(
                [UInt8](buffer),
                [UInt8](repeating: 2, count: 15) +
                    [UInt8](repeating: 3, count: 5))
            assertEqual(input.readPosition, input.storage + 20)
            assertEqual(input.writePosition, input.storage + 40)

            buffer = try input.read(count: 10)
            assertEqual([UInt8](buffer), [UInt8](repeating: 3, count: 10))
            assertEqual(input.readPosition, input.storage + 30)
            assertEqual(input.writePosition, input.storage + 40)
            assertEqual(input.allocated, 40)

            // shift << the content because it's < capacity / 2
            buffer = try input.read(count: 20)
            assertEqual([UInt8](buffer),
                [UInt8](repeating: 3, count: 10) +
                    [UInt8](repeating: 4, count: 10))
            assertEqual(input.readPosition, input.storage + 20)
            assertEqual(input.writePosition, input.storage + 40)
            assertEqual(input.allocated, 40)

        } catch {
            fail(String(describing: error))
        }
    }

    func testReadReservingCapacity() {
        do {
            let input = BufferedInputStream(
                baseStream: TestStream(),
                capacity: 10)
            assertEqual(input.expandable, true)
            assertEqual(input.allocated, 10)

            var buffer = try input.read(count: 10)
            assertEqual([UInt8](buffer), [UInt8](repeating: 1, count: 10))
            assertEqual(input.readPosition, input.storage)
            assertEqual(input.writePosition, input.storage)

            buffer = try input.read(count: 10)
            assertEqual([UInt8](buffer), [UInt8](repeating: 2, count: 10))
            assertEqual(input.readPosition, input.storage)
            assertEqual(input.writePosition, input.storage)
        } catch {
            fail(String(describing: error))
        }
    }

    func testReadFixedCapacity() {
        do {
            let input = BufferedInputStream(
                baseStream: TestStream(),
                capacity: 10,
                expandable: false)
            assertEqual(input.expandable, false)
            assertEqual(input.allocated, 10)

            var buffer = try input.read(count: 10)
            assertEqual([UInt8](buffer), [UInt8](repeating: 1, count: 10))
            assertEqual(input.readPosition, input.storage)
            assertEqual(input.writePosition, input.storage)

            assertThrowsError(try input.read(count: 11)) { error in
                assertEqual(.notEnoughSpace, error as? StreamError)
            }

            assertEqual(input.readPosition, input.storage)
            assertEqual(input.writePosition, input.storage)


            buffer = try input.read(count: 2)
            assertEqual([UInt8](buffer), [UInt8](repeating: 2, count: 2))
            assertEqual(input.readPosition, input.storage + 2)
            assertEqual(input.writePosition, input.storage + 10)

            // shift the rest and fill with another read
            buffer = try input.read(count: 9)
            assertEqual([UInt8](buffer), [UInt8](repeating: 2, count: 8) + [3])
            assertEqual(input.readPosition, input.storage + 9)
            assertEqual(input.writePosition, input.storage + 10)

        } catch {
            fail(String(describing: error))
        }
    }

    func testReadByte() {
        let stream = TestStream(generateBytesCount: 4)
        let input = BufferedInputStream(baseStream: stream, capacity: 2)

        assertEqual(try input.read(UInt8.self), 1)
        assertEqual(try input.read(UInt8.self), 1)
        assertEqual(try input.read(UInt8.self), 2)
        assertEqual(try input.read(UInt8.self), 2)

        assertThrowsError(try input.read(UInt8.self)) { error in
            assertEqual(error as? StreamError, .insufficientData)
        }
    }

    func testReadWhile() {
        do {
            let input = BufferedInputStream(
                baseStream: TestStream(),
                capacity: 5)
            assertEqual(input.expandable, true)
            assertEqual(input.allocated, 5)

            let buffer = try input.read(while: { $0 != 3 })
            assertEqual([UInt8](buffer),
                [UInt8](repeating: 1, count: 5) +
                    [UInt8](repeating: 2, count: 7))
            assertEqual(input.readPosition, input.storage + 12)
            assertEqual(input.writePosition, input.storage + 26)
        } catch {
            fail(String(describing: error))
        }
    }

    func testReadWhileAllowingExhaustion() {
        let stream = TestStream(generateBytesCount: 5)
        let input = BufferedInputStream(baseStream: stream, capacity: 5)

        assertThrowsError(try input.read(
            while: { $0 == 1 },
            allowingExhaustion: false)) { error in
                assertEqual(error as? StreamError, .insufficientData)
        }

        assertEqual(input.buffered, 0)

        assertNoThrow(try input.read(
            while: { $0 == 1 },
            allowingExhaustion: true))
    }

    func testReadUntil() {
        do {
            let input = BufferedInputStream(
                baseStream: TestStream(),
                capacity: 5)
            assertEqual(input.expandable, true)
            assertEqual(input.allocated, 5)

            try input.read(until: 3) { buffer in
                let expected =
                    [UInt8](repeating: 1, count: 5) +
                    [UInt8](repeating: 2, count: 7)
                assertEqual([UInt8](buffer), expected)
            }
            assertEqual(input.readPosition, input.storage + 12)
            assertEqual(input.writePosition, input.storage + 26)
        } catch {
            fail(String(describing: error))
        }
    }

    func testPeek() {
        let stream = TestStream(generateBytesCount: 10)
        let input = BufferedInputStream(
            baseStream: stream, capacity: 10, expandable: false)
        assertTrue(try input.feed())
        assertEqual(input.readPosition, input.storage)
        assertEqual(input.writePosition, input.storage + 10)

        assertThrowsError(try input.cache(count: 15)) { error in
            assertEqual(.notEnoughSpace, error as? StreamError)
        }

        assertNoThrow(try input.cache(count: 5))
        assertTrue(try input.next(is: [UInt8](repeating: 1, count: 5)))
        assertEqual(input.readPosition, input.storage)
        assertEqual(input.writePosition, input.storage + 10)

        assertNoThrow(try input.read(count: 10))
        assertFalse(try input.cache(count: 5))
    }

    func testConsume() {
        do {
            let input = BufferedInputStream(
                baseStream: TestStream(),
                capacity: 10)
            assertEqual(input.readPosition, input.storage)
            assertEqual(input.writePosition, input.storage)

            try input.consume(count: 5)

            assertEqual(input.readPosition, input.storage + 5)
            assertEqual(input.writePosition, input.storage + 10)

            try input.consume(count: 5)

            assertEqual(input.readPosition, input.storage)
            assertEqual(input.writePosition, input.storage)

            let buffer = try input.read(count: 5)
            assertEqual([UInt8](buffer), [UInt8](repeating: 2, count: 5))
            assertEqual(input.readPosition, input.storage + 5)
            assertEqual(input.writePosition, input.storage + 10)
        } catch {
            fail(String(describing: error))
        }
    }

    func testConsumeNotExpandable() {
        do {
            let input = BufferedInputStream(
                baseStream: TestStream(),
                capacity: 10,
                expandable: false)
            assertEqual(input.readPosition, input.storage)
            assertEqual(input.writePosition, input.storage)
            assertEqual(input.expandable, false)
            assertEqual(input.allocated, 10)

            try input.consume(count: 15)

            assertEqual(input.readPosition, input.storage + 5)
            assertEqual(input.writePosition, input.storage + 10)
            assertEqual(input.expandable, false)
            assertEqual(input.allocated, 10)

            let buffer = try input.read(count: 5)
            assertEqual([UInt8](buffer), [UInt8](repeating: 2, count: 5))
            assertEqual(input.readPosition, input.storage)
            assertEqual(input.writePosition, input.storage)
        } catch {
            fail(String(describing: error))
        }
    }

    func testConsumeByte() {
        let stream =  TestStream(generateBytesCount: 2)
        let input = BufferedInputStream(baseStream: stream)
        assertEqual(input.buffered, 0)

        assertTrue(try input.consume(UInt8(1)))
        assertEqual(input.buffered, 1)

        assertFalse(try input.consume(UInt8(2)))
        assertEqual(input.buffered, 1)

        assertTrue(try input.consume(UInt8(1)))
        assertEqual(input.buffered, 0)

        assertThrowsError(try input.consume(1)) { error in
            assertEqual(error as? StreamError, .insufficientData)
        }
    }

    func testConsumeWhile() {
        do {
            let input = BufferedInputStream(
                baseStream: TestStream(),
                capacity: 2)
            assertEqual(input.readPosition, input.storage)
            assertEqual(input.writePosition, input.storage)
            assertEqual(input.allocated, 2)
            assertEqual(input.buffered, 0)

            try input.consume(while: { $0 == 1 || $0 == 2 })

            assertEqual(input.readPosition, input.storage)
            assertEqual(input.writePosition, input.storage + 2)
            assertEqual(input.allocated, 2)
            assertEqual(input.buffered, 2)

            let buffer = try input.read(count: 10)
            assertEqual(input.allocated, 24)
            assertEqual(input.buffered, 14)

            assertEqual([UInt8](buffer),
                [UInt8](repeating: 3, count: 2)
                    + [UInt8](repeating: 4, count: 8))
            assertEqual(input.readPosition, input.storage + 10)
            assertEqual(input.writePosition, input.storage + 24)
        } catch {
            fail(String(describing: error))
        }
    }

    func testConsumeUntil() {
        do {
            let input = BufferedInputStream(
                baseStream: TestStream(),
                capacity: 2)
            assertEqual(input.readPosition, input.storage)
            assertEqual(input.writePosition, input.storage)
            assertEqual(input.allocated, 2)
            assertEqual(input.buffered, 0)

            try input.consume(until: 3)

            assertEqual(input.readPosition, input.storage)
            assertEqual(input.writePosition, input.storage + 2)
            assertEqual(input.allocated, 2)
            assertEqual(input.buffered, 2)

            let buffer = try input.read(count: 10)
            assertEqual(input.allocated, 24)
            assertEqual(input.buffered, 14)

            assertEqual([UInt8](buffer),
                [UInt8](repeating: 3, count: 2)
                    + [UInt8](repeating: 4, count: 8))
            assertEqual(input.readPosition, input.storage + 10)
            assertEqual(input.writePosition, input.storage + 24)
        } catch {
            fail(String(describing: error))
        }
    }

    func testFeedLessThanReadCount() {
        do {
            let stream = TestStream(generateBytesCount: 20)
            let input = BufferedInputStream(baseStream: stream, capacity: 10)
            assertEqual(input.readPosition, input.storage)
            assertEqual(input.writePosition, input.storage)

            let buffer = try input.read(count: 20)
            assertEqual([UInt8](buffer), [UInt8](repeating: 1, count: 20))
        } catch {
            fail(String(describing: error))
        }
    }
}
