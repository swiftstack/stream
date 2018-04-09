import Test
@testable import Stream

class MemoryStreamTests: TestCase {
    func testMemoryStream() {
        let stream = MemoryStream()
        assertNotNil(stream)
    }

    func testInputStream() {
        let stream = MemoryStream() as InputStream
        assertNotNil(stream)
    }

    func testOutputStream() {
        let stream = MemoryStream() as OutputStream
        assertNotNil(stream)
    }

    func testInitialSize() {
        let stream = MemoryStream()
        assertEqual(stream.capacity, 0)
        assertEqual(stream.position, 0)
        assertEqual(stream.remain, 0)
    }

    func testWriteEmpty() {
        let stream = MemoryStream()
        let buffer = [UInt8]()

        let written = try? stream.write(
            from: UnsafeRawPointer(buffer),
            byteCount: 0)
        assertEqual(written, 0)
    }

    func testReadEmpty() {
        let stream = MemoryStream()
        let buffer = [UInt8]()

        let read = try? stream.read(
            to: UnsafeMutableRawPointer(mutating: buffer),
            byteCount: 10)
        assertEqual(read, 0)
    }

    func testSeek() {
        let stream = MemoryStream()
        assertNotNil(stream as Seekable)
        assertEqual(stream.position, 0)
        assertEqual(stream.remain, 0)
        assertEqual(stream.count, 0)

        _ = try! stream.write(from: [1, 2, 3, 4])
        assertEqual(stream.position, 4)
        assertEqual(stream.remain, 0)
        assertEqual(stream.count, 4)

        assertNoThrow(try stream.seek(to: 1, from: .begin))
        assertEqual(stream.position, 1)
        assertEqual(stream.remain, 3)
        assertEqual(stream.count, 4)

        assertNoThrow(try stream.seek(to: 2, from: .current))
        assertEqual(stream.position, 3)
        assertEqual(stream.remain, 1)
        assertEqual(stream.count, 4)

        assertNoThrow(try stream.seek(to: -4, from: .end))
        assertEqual(stream.position, 0)
        assertEqual(stream.remain, 4)
        assertEqual(stream.count, 4)

        assertThrowsError(try stream.seek(to: -1, from: .begin)) { error in
            assertEqual(error as? MemoryStream.Error, .invalidSeekOffset)
        }

        assertThrowsError(try stream.seek(to: 5, from: .begin)) { error in
            assertEqual(error as? MemoryStream.Error, .invalidSeekOffset)
        }

        assertThrowsError(try stream.seek(to: -1, from: .current)) { error in
            assertEqual(error as? MemoryStream.Error, .invalidSeekOffset)
        }

        assertThrowsError(try stream.seek(to: 5, from: .current)) { error in
            assertEqual(error as? MemoryStream.Error, .invalidSeekOffset)
        }

        assertThrowsError(try stream.seek(to: 1, from: .end)) { error in
            assertEqual(error as? MemoryStream.Error, .invalidSeekOffset)
        }

        assertThrowsError(try stream.seek(to: -5, from: .end)) { error in
            assertEqual(error as? MemoryStream.Error, .invalidSeekOffset)
        }
    }

    func testWrite() {
        let stream = MemoryStream()
        let data: [UInt8] = [1, 2, 3, 4]

        let written = try? stream.write(from: data, byteCount: 4)
        assertEqual(written, 4)

        var buffer = [UInt8](repeating: 0, count: 4)
        assertNoThrow(try stream.seek(to: 0, from: .begin))
        assertNoThrow(try stream.read(to: &buffer, byteCount: 4))
        assertEqual(buffer, [1, 2, 3, 4])


        buffer = [UInt8](repeating: 0, count: 4)
        assertNoThrow(try stream.seek(to: 0, from: .begin))

        let writtenFirst = try? stream.write(from: data, byteCount: 2)
        assertEqual(writtenFirst, 2)
        assertNoThrow(try stream.seek(to: 0, from: .begin))
        assertNoThrow(try stream.read(to: &buffer, byteCount: 2))
        assertEqual(buffer, [1, 2, 0, 0])

        assertNoThrow(try stream.seek(to: 0, from: .end))
        let writtenLast = try? stream.write(from: data.suffix(from: 2))
        assertEqual(writtenLast, 2)
        assertNoThrow(try stream.seek(to: -2, from: .end))
        assertNoThrow(try stream.read(to: &buffer[2], byteCount: 2))
        assertEqual(buffer, data)
    }

    func testRead() {
        let stream = MemoryStream()
        let data: [UInt8] = [1, 2, 3, 4]
        assertNoThrow(try stream.write(from: data, byteCount: 4))

        var buffer = [UInt8](repeating: 0, count: 4)
        assertNoThrow(try stream.seek(to: 0, from: .begin))

        let read = try? stream.read(to: &buffer, byteCount: 4)
        assertEqual(read, 4)
        assertEqual(buffer, data)
        assertEqual(stream.position, 4)
        assertEqual(stream.remain, 0)
        assertEqual(stream.count, 4)


        buffer = [UInt8](repeating: 0, count: 4)
        assertNoThrow(try stream.seek(to: 0, from: .begin))

        let readFirst = try? stream.read(to: &buffer, byteCount: 2)
        assertEqual(readFirst, 2)
        assertEqual(buffer, [1, 2, 0, 0])
        assertEqual(stream.position, 2)
        assertEqual(stream.remain, 2)
        assertEqual(stream.count, 4)

        let readLast = try? stream.read(to: &buffer[2], byteCount: 2)
        assertEqual(readLast, 2)
        assertEqual(buffer, data)
        assertEqual(stream.position, 4)
        assertEqual(stream.remain, 0)
        assertEqual(stream.count, 4)
    }

    func testReallocate() {
        let stream = MemoryStream()
        let data: [UInt8] = [1, 2, 3, 4, 5, 6, 7, 8]

        assertEqual(stream.capacity, 0)
        assertEqual(stream.position, 0)

        _ = try? stream.write(from: data, byteCount: data.count)
        assertEqual(stream.capacity, 256)
        assertEqual(stream.position, 8)
        assertEqual(stream.remain, 0)
        assertEqual(stream.count, 8)

        let data300 = [UInt8](repeating: 111, count: 300)

        _ = try? stream.write(from: data300, byteCount: data300.count)
        assertEqual(stream.capacity, 512)
        assertEqual(stream.position, 308)
        assertEqual(stream.remain, 0)
        assertEqual(stream.count, 308)

        var buffer = [UInt8](repeating: 0, count: 308)
        try? stream.seek(to: 0, from: .begin)
        _ = try? stream.read(to: &buffer, byteCount: buffer.count)
        assertEqual(buffer, [1, 2, 3, 4, 5, 6, 7, 8] + data300)
        assertEqual(stream.capacity, 512)
        assertEqual(stream.position, 308)
        assertEqual(stream.remain, 0)
        assertEqual(stream.count, 308)
    }

    func testCapacity() {
        let stream = MemoryStream(capacity: 4)
        let data: [UInt8] = [1, 2, 3, 4]
        assertNoThrow(try stream.write(from: data, byteCount: 2))

        assertThrowsError(try stream.write(from: data, byteCount: 4)) { error in
            assertEqual(error as? MemoryStream.Error, .notEnoughSpace)
        }
    }

    func testTrivial() {
        let stream = MemoryStream()
        var buffer = [UInt8](repeating: 0, count: 8)

        _ = try? stream.write(0x0102030405060708)
        try? stream.seek(to: 0, from: .begin)
        let read = try? stream.read(to: &buffer, byteCount: 8)
        assertEqual(read, 8)
        assertEqual(buffer, [1, 2, 3, 4, 5, 6, 7, 8])

        try? stream.seek(to: 0, from: .begin)
        assertNoThrow(try stream.write(Int.max))
        assertNoThrow(try stream.write(Int8.max))
        assertNoThrow(try stream.write(Int16.max))
        assertNoThrow(try stream.write(Int32.max))
        assertNoThrow(try stream.write(Int64.max))
        assertNoThrow(try stream.write(UInt.max))
        assertNoThrow(try stream.write(UInt8.max))
        assertNoThrow(try stream.write(UInt16.max))
        assertNoThrow(try stream.write(UInt32.max))
        assertNoThrow(try stream.write(UInt64.max))

        try? stream.seek(to: 0, from: .begin)
        assertEqual(try? stream.read(Int.self), Int.max)
        assertEqual(try? stream.read(Int8.self), Int8.max)
        assertEqual(try? stream.read(Int16.self), Int16.max)
        assertEqual(try? stream.read(Int32.self), Int32.max)
        assertEqual(try? stream.read(Int64.self), Int64.max)
        assertEqual(try? stream.read(UInt.self), UInt.max)
        assertEqual(try? stream.read(UInt8.self), UInt8.max)
        assertEqual(try? stream.read(UInt16.self), UInt16.max)
        assertEqual(try? stream.read(UInt32.self), UInt32.max)
        assertEqual(try? stream.read(UInt64.self), UInt64.max)

        assertThrowsError(try stream.read(Int.self)) { error in
            assertEqual(error as? MemoryStream.Error, .insufficientData)
        }

        assertNoThrow(try stream.write(UInt32.max))
        try! stream.seek(to: -MemoryLayout<UInt32>.size, from: .end)
        assertThrowsError(try stream.read(UInt64.self)) { error in
            assertEqual(error as? MemoryStream.Error, .insufficientData)
        }
    }

    func testBuffer() {
        let stream = MemoryStream(capacity: 4)
        let data: [UInt8] = [1, 2, 3, 4]

        assertNoThrow(try stream.write(from: data, byteCount: 4))
        assertEqual([1, 2, 3, 4], [UInt8](stream.buffer))

        var buffer = [UInt8](repeating: 0, count: 1)
        assertNoThrow(try stream.read(to: &buffer))
        assertEqual([1, 2, 3, 4], [UInt8](stream.buffer))
    }
}
