import Test
@testable import Stream

class BufferedStreamReaderTests: TestCase {
    class TestStream: InputStream {
        var counter: UInt8 = 0

        func read(to buffer: UnsafeMutableRawBufferPointer) throws -> Int {
            counter = counter &+ 1
            for i in 0..<buffer.count {
                buffer[i] = counter
            }
            return buffer.count
        }
    }

    func testInitialState() {
        let input = BufferedInputStream(baseStream: TestStream())
        assertEqual(input.writePosition, 0)
        assertEqual(input.readPosition, 0)
        assertEqual(input.capacity, 0)
        assertEqual(input.count, 0)
    }

    func testRead() {
        do {
            let input = BufferedInputStream(baseStream: TestStream())
            assertEqual(input.expandable, true)
            assertEqual(input.capacity, 0)

            var buffer = try input.read(count: 10)
            assertTrue(buffer.elementsEqual([UInt8](repeating: 1, count: 10)))
            assertEqual(input.readPosition, 10)
            // default size(0) is < requested,
            // so we reserve requested(10) * 2
            assertEqual(input.writePosition, 20)

            // stil have buffered data
            buffer = try input.read(count: 10)
            assertTrue(buffer.elementsEqual([UInt8](repeating: 1, count: 10)))
            assertEqual(input.readPosition, 0)
            assertEqual(input.writePosition, 0)

            // buffer is empty so another read
            // from the source stream initiated
            buffer = try input.read(count: 5)
            assertTrue(buffer.elementsEqual([UInt8](repeating: 2, count: 5)))
            assertEqual(input.readPosition, 5)
            assertEqual(input.writePosition, 20)

            // stil have 15 bytes
            // reallocate x2 because the content is > capacity / 2
            buffer = try input.read(count: 20)
            assertTrue(buffer.elementsEqual(
                [UInt8](repeating: 2, count: 15) +
                    [UInt8](repeating: 3, count: 5)))
            assertEqual(input.readPosition, 20)
            assertEqual(input.writePosition, 40)

            buffer = try input.read(count: 10)
            assertTrue(buffer.elementsEqual([UInt8](repeating: 3, count: 10)))
            assertEqual(input.readPosition, 30)
            assertEqual(input.writePosition, 40)
            assertEqual(input.capacity, 40)

            // shift << the content because it's < capacity / 2
            buffer = try input.read(count: 20)
            assertTrue(buffer.elementsEqual(
                [UInt8](repeating: 3, count: 10) +
                    [UInt8](repeating: 4, count: 10)))
            assertEqual(input.readPosition, 20)
            assertEqual(input.writePosition, 40)
            assertEqual(input.capacity, 40)

        } catch {
            fail(String(describing: error))
        }
    }

    func testReadReservingCapacity() {
        do {
            let input = BufferedInputStream(baseStream: TestStream(), capacity: 10)
            assertEqual(input.expandable, true)
            assertEqual(input.capacity, 10)

            var buffer = try input.read(count: 10)
            assertTrue(buffer.elementsEqual([UInt8](repeating: 1, count: 10)))
            assertEqual(input.readPosition, 0)
            assertEqual(input.writePosition, 0)

            buffer = try input.read(count: 10)
            assertTrue(buffer.elementsEqual([UInt8](repeating: 2, count: 10)))
            assertEqual(input.readPosition, 0)
            assertEqual(input.writePosition, 0)
        } catch {
            fail(String(describing: error))
        }
    }

    func testReadFixedCapacity() {
        do {
            let input = BufferedInputStream(
                baseStream: TestStream(), capacity: 10, expandable: false)
            assertEqual(input.expandable, false)
            assertEqual(input.capacity, 10)

            var buffer = try input.read(count: 10)
            assertTrue(buffer.elementsEqual([UInt8](repeating: 1, count: 10)))
            assertEqual(input.readPosition, 0)
            assertEqual(input.writePosition, 0)

            assertThrowsError(try input.read(count: 11)) { error in
                assertEqual(.notEnoughSpace, error as? BufferError)
            }

            assertEqual(input.readPosition, 0)
            assertEqual(input.writePosition, 0)


            buffer = try input.read(count: 2)
            assertTrue(buffer.elementsEqual([UInt8](repeating: 2, count: 2)))
            assertEqual(input.readPosition, 2)
            assertEqual(input.writePosition, 10)

            // shift the rest and fill with another read
            buffer = try input.read(count: 9)
            assertTrue(buffer.elementsEqual([UInt8](repeating: 2, count: 8) + [3]))
            assertEqual(input.readPosition, 9)
            assertEqual(input.writePosition, 10)

        } catch {
            fail(String(describing: error))
        }
    }

    func testReadWhile() {
        do {
            let input = BufferedInputStream(baseStream: TestStream(), capacity: 5)
            assertEqual(input.expandable, true)
            assertEqual(input.capacity, 5)

            guard let buffer = try input.read(while: { $0 != 3 }) else {
                fail()
                return
            }
            assertTrue(buffer.elementsEqual(
                [UInt8](repeating: 1, count: 5) +
                    [UInt8](repeating: 2, count: 7)))
            assertEqual(input.readPosition, 12)
            assertEqual(input.writePosition, 26)
        } catch {
            fail(String(describing: error))
        }
    }

    func testReadUntil() {
        do {
            let input = BufferedInputStream(baseStream: TestStream(), capacity: 5)
            assertEqual(input.expandable, true)
            assertEqual(input.capacity, 5)

            guard let buffer = try input.read(until: 3) else {
                fail()
                return
            }
            assertTrue(buffer.elementsEqual(
                [UInt8](repeating: 1, count: 5) +
                    [UInt8](repeating: 2, count: 7)))
            assertEqual(input.readPosition, 12)
            assertEqual(input.writePosition, 26)
        } catch {
            fail(String(describing: error))
        }
    }

    func testPeek() {
        let input = BufferedInputStream(baseStream: TestStream(), capacity: 10)
        assertEqual(try input.feed(), 10)
        assertEqual(input.readPosition, 0)
        assertEqual(input.writePosition, 10)

        assertNil(input.peek(count: 15))

        guard let buffer = input.peek(count: 5) else {
            fail()
            return
        }
        assertTrue(buffer.elementsEqual([UInt8](repeating: 1, count: 5)))
        assertEqual(input.readPosition, 0)
        assertEqual(input.writePosition, 10)
    }

    func testConsume() {
        do {
            let input = BufferedInputStream(baseStream: TestStream(), capacity: 10)
            assertEqual(input.readPosition, 0)
            assertEqual(input.writePosition, 0)

            try input.consume(count: 5)

            assertEqual(input.readPosition, 5)
            assertEqual(input.writePosition, 10)

            try input.consume(count: 5)

            assertEqual(input.readPosition, 0)
            assertEqual(input.writePosition, 0)

            let buffer = try input.read(count: 5)
            assertTrue(buffer.elementsEqual([UInt8](repeating: 2, count: 5)))
            assertEqual(input.readPosition, 5)
            assertEqual(input.writePosition, 10)
        } catch {
            fail(String(describing: error))
        }
    }

    func testConsumeWhile() {
        do {
            let input = BufferedInputStream(baseStream: TestStream())
            assertEqual(input.readPosition, 0)
            assertEqual(input.writePosition, 0)

            guard try input.consume(while: { $0 == 1 || $0 == 2 }) else {
                fail()
                return
            }

            assertEqual(input.readPosition, 0)
            assertEqual(input.writePosition, 2)

            let buffer = try input.read(count: 10)
            assertTrue(buffer.elementsEqual(
                [UInt8](repeating: 3, count: 2)
                    + [UInt8](repeating: 4, count: 8)))
            assertEqual(input.readPosition, 10)
            assertEqual(input.writePosition, 24)
        } catch {
            fail(String(describing: error))
        }
    }

    func testConsumeUntil() {
        do {
            let input = BufferedInputStream(baseStream: TestStream())
            assertEqual(input.readPosition, 0)
            assertEqual(input.writePosition, 0)

            guard try input.consume(until: 3) else {
                fail()
                return
            }

            assertEqual(input.readPosition, 0)
            assertEqual(input.writePosition, 2)

            let buffer = try input.read(count: 10)
            assertTrue(buffer.elementsEqual(
                [UInt8](repeating: 3, count: 2)
                    + [UInt8](repeating: 4, count: 8)))
            assertEqual(input.readPosition, 10)
            assertEqual(input.writePosition, 24)
        } catch {
            fail(String(describing: error))
        }
    }

    func testFeedLessThanReadCount() {
        class TenStream: InputStream {
            func read(to buffer: UnsafeMutableRawBufferPointer) throws -> Int {
                for i in 0..<10 {
                    buffer[i] = 10
                }
                return 10
            }
        }

        do {
            let input = BufferedInputStream(baseStream: TenStream(), capacity: 10)
            assertEqual(input.readPosition, 0)
            assertEqual(input.writePosition, 0)

            let buffer = try input.read(count: 20)
            assertTrue(buffer.elementsEqual([UInt8](repeating: 10, count: 20)))
        } catch {
            fail(String(describing: error))
        }
    }
}
