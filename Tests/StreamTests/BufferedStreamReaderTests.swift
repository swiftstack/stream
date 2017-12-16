import Test
@testable import Stream

class BufferedStreamReaderTests: TestCase {
    class TestStream: InputStream {
        var counter: UInt8 = 0

        func read(
            to buffer: UnsafeMutableRawPointer, byteCount: Int
        ) throws -> Int {
            counter = counter &+ 1
            for i in 0..<byteCount {
                buffer.advanced(by: i)
                    .assumingMemoryBound(to: UInt8.self)
                    .pointee = counter
            }
            return byteCount
        }
    }

    func testInitialState() {
        let input = BufferedInputStream(baseStream: TestStream())
        assertEqual(input.writePosition, input.storage)
        assertEqual(input.readPosition, input.storage)
        assertEqual(input.allocated, 0)
        assertEqual(input.count, 0)
    }

    func testRead() {
        do {
            let input = BufferedInputStream(baseStream: TestStream())
            assertEqual(input.expandable, true)
            assertEqual(input.allocated, 0)

            var buffer = try input.read(count: 10)
            assertEqual([UInt8](buffer), [UInt8](repeating: 1, count: 10))
            assertEqual(input.readPosition, input.storage + 10)
            // default size(0) is < requested,
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
            let input = BufferedInputStream(baseStream: TestStream(), capacity: 10)
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
                baseStream: TestStream(), capacity: 10, expandable: false)
            assertEqual(input.expandable, false)
            assertEqual(input.allocated, 10)

            var buffer = try input.read(count: 10)
            assertEqual([UInt8](buffer), [UInt8](repeating: 1, count: 10))
            assertEqual(input.readPosition, input.storage)
            assertEqual(input.writePosition, input.storage)

            assertThrowsError(try input.read(count: 11)) { error in
                assertEqual(.notEnoughSpace, error as? BufferError)
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

    func testReadWhile() {
        do {
            let input = BufferedInputStream(baseStream: TestStream(), capacity: 5)
            assertEqual(input.expandable, true)
            assertEqual(input.allocated, 5)

            guard let buffer = try input.read(while: { $0 != 3 }) else {
                fail()
                return
            }
            assertEqual([UInt8](buffer),
                [UInt8](repeating: 1, count: 5) +
                    [UInt8](repeating: 2, count: 7))
            assertEqual(input.readPosition, input.storage + 12)
            assertEqual(input.writePosition, input.storage + 26)
        } catch {
            fail(String(describing: error))
        }
    }

    func testReadUntil() {
        do {
            let input = BufferedInputStream(baseStream: TestStream(), capacity: 5)
            assertEqual(input.expandable, true)
            assertEqual(input.allocated, 5)

            guard let buffer = try input.read(until: 3) else {
                fail()
                return
            }
            assertEqual([UInt8](buffer),
                [UInt8](repeating: 1, count: 5) +
                    [UInt8](repeating: 2, count: 7))
            assertEqual(input.readPosition, input.storage + 12)
            assertEqual(input.writePosition, input.storage + 26)
        } catch {
            fail(String(describing: error))
        }
    }

    func testPeek() {
        let input = BufferedInputStream(baseStream: TestStream(), capacity: 10)
        assertEqual(try input.feed(), 10)
        assertEqual(input.readPosition, input.storage)
        assertEqual(input.writePosition, input.storage + 10)

        assertNil(input.peek(count: 15))

        guard let buffer = input.peek(count: 5) else {
            fail()
            return
        }
        assertEqual([UInt8](buffer), [UInt8](repeating: 1, count: 5))
        assertEqual(input.readPosition, input.storage)
        assertEqual(input.writePosition, input.storage + 10)
    }

    func testConsume() {
        do {
            let input = BufferedInputStream(baseStream: TestStream(), capacity: 10)
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

    func testConsumeWhile() {
        do {
            let input = BufferedInputStream(baseStream: TestStream())
            assertEqual(input.readPosition, input.storage)
            assertEqual(input.writePosition, input.storage)

            guard try input.consume(while: { $0 == 1 || $0 == 2 }) else {
                fail()
                return
            }

            assertEqual(input.readPosition, input.storage)
            assertEqual(input.writePosition, input.storage + 2)

            let buffer = try input.read(count: 10)
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
            let input = BufferedInputStream(baseStream: TestStream())
            assertEqual(input.readPosition, input.storage)
            assertEqual(input.writePosition, input.storage)

            guard try input.consume(until: 3) else {
                fail()
                return
            }

            assertEqual(input.readPosition, input.storage)
            assertEqual(input.writePosition, input.storage + 2)

            let buffer = try input.read(count: 10)
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
        class TenStream: InputStream {
            func read(
                to buffer: UnsafeMutableRawPointer, byteCount: Int
            ) throws -> Int {
                for i in 0..<10 {
                    buffer.advanced(by: i)
                        .assumingMemoryBound(to: UInt8.self)
                        .pointee = 10
                }
                return 10
            }
        }

        do {
            let input = BufferedInputStream(baseStream: TenStream(), capacity: 10)
            assertEqual(input.readPosition, input.storage)
            assertEqual(input.writePosition, input.storage)

            let buffer = try input.read(count: 20)
            assertEqual([UInt8](buffer), [UInt8](repeating: 10, count: 20))
        } catch {
            fail(String(describing: error))
        }
    }
}
