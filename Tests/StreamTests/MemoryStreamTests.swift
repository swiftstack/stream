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

    func testWriteEmpty() {
        let stream = MemoryStream()
        let buffer = [UInt8]()

        let written = try? stream.write(
            from: UnsafeRawPointer(buffer),
            count: 0)
        assertEqual(written, 0)
    }

    func testReadEmpty() {
        let stream = MemoryStream()
        let buffer = [UInt8]()

        let read = try? stream.read(
            to: UnsafeMutableRawPointer(mutating: buffer),
            count: 10)
        assertEqual(read, 0)
    }

    func testWrite() {
        let stream = MemoryStream()
        let data: [UInt8] = [1, 2, 3, 4]

        let written = try? stream.write(from: data, count: 4)
        assertEqual(written, 4)
    }

    func testRead() {
        let stream = MemoryStream()
        let data: [UInt8] = [1, 2, 3, 4]
        var buffer = [UInt8](repeating: 0, count: 4)
        _ = try? stream.write(from: data, count: 4)

        let read = try? stream.read(to: &buffer, count: 4)
        assertEqual(read, 4)
        assertEqual(buffer, data)
    }

    func testWriteOffset() {
        let stream = MemoryStream()
        let data: [UInt8] = [1, 2, 3, 4]

        let written = try? stream.write(from: data, offset: 2, count: 2)
        assertEqual(written, 2)

        var buffer = [UInt8](repeating: 0, count: 2)
        _ = try? stream.read(to: &buffer, count: 2)
        assertEqual(buffer, [3, 4])
    }

    func testReadOffset() {
        let stream = MemoryStream()
        let data: [UInt8] = [1, 2, 3, 4]

        _ = try? stream.write(from: data, count: 4)

        var buffer = [UInt8](repeating: 0, count: 4)
        let read = try? stream.read(to: &buffer, offset: 2, count: 2)
        assertEqual(read, 2)
        assertEqual(buffer, [0, 0, 1, 2])
    }

    func testWritePiece() {
        let stream = MemoryStream()
        let data: [UInt8] = [1, 2, 3, 4]
        var buffer = [UInt8](repeating: 0, count: 4)

        let writtenFirst = try? stream.write(from: data, count: 2)
        assertEqual(writtenFirst, 2)
        _ = try? stream.read(to: &buffer, count: 2)
        assertEqual(buffer, [1, 2, 0, 0])

        let writtenLast = try? stream.write(from: data, offset: 2, count: 2)
        assertEqual(writtenLast, 2)
        _ = try? stream.read(to: &buffer, offset: 2, count: 2)
        assertEqual(buffer, data)
    }

    func testReadPiece() {
        let stream = MemoryStream()
        let data: [UInt8] = [1, 2, 3, 4]
        var buffer = [UInt8](repeating: 0, count: 4)
        _ = try? stream.write(from: data, count: 4)

        let readFirst = try? stream.read(to: &buffer, count: 2)
        assertEqual(readFirst, 2)
        assertEqual(buffer, [1, 2, 0, 0])

        let readLast = try? stream.read(to: &buffer, offset: 2, count: 2)
        assertEqual(readLast, 2)
        assertEqual(buffer, data)
    }

    func testInitialSize() {
        let stream = MemoryStream()
        assertEqual(stream.allocated, 8)
        assertEqual(stream.start, 0)
        assertEqual(stream.count, 0)
    }

    func testShift() {
        let stream = MemoryStream()
        let data: [UInt8] = [1, 2, 3, 4, 5, 6, 7, 8]

        _ = try? stream.write(from: data, count: data.count)
        assertEqual(stream.allocated, 8)
        assertEqual(stream.start, 0)
        assertEqual(stream.count, 8)

        var buffer = [UInt8](repeating: 0, count: 6)
        _ = try? stream.read(to: &buffer, count: buffer.count)
        assertEqual(buffer, [1, 2, 3, 4, 5, 6])
        assertEqual(stream.allocated, 8)
        assertEqual(stream.start, 6)
        assertEqual(stream.count, 2)

        _ = try? stream.write(from: data, offset: 4, count: 2)
        assertEqual(stream.allocated, 8)
        assertEqual(stream.start, 0)
        assertEqual(stream.count, 4)

        buffer = [UInt8](repeating: 0, count: 4)
        _ = try? stream.read(to: &buffer, count: buffer.count)
        assertEqual(buffer, [7, 8, 5, 6])
        assertEqual(stream.allocated, 8)
        assertEqual(stream.start, 0)
        assertEqual(stream.count, 0)
    }

    func testReallocate() {
        let stream = MemoryStream()
        let data: [UInt8] = [1, 2, 3, 4, 5, 6, 7, 8]

        _ = try? stream.write(from: data, count: data.count)
        assertEqual(stream.allocated, 8)
        assertEqual(stream.start, 0)
        assertEqual(stream.count, 8)

        _ = try? stream.write(from: data, count: data.count)
        assertEqual(stream.allocated, 32)
        assertEqual(stream.start, 0)
        assertEqual(stream.count, 16)

        var buffer = [UInt8](repeating: 0, count: 16)
        _ = try? stream.read(to: &buffer, count: buffer.count)
        assertEqual(buffer, [1, 2, 3, 4, 5, 6, 7, 8, 1, 2, 3, 4, 5, 6, 7, 8])
        assertEqual(stream.allocated, 32)
        assertEqual(stream.start, 0)
        assertEqual(stream.count, 0)
    }

    func testCapacity() {
        let stream = MemoryStream(capacity: 4)
        let data: [UInt8] = [1, 2, 3, 4]
        assertNoThrow(try stream.write(from: data, count: 4))

        assertThrowsError(try stream.write(from: data, count: 4)) { error in
            assertEqual(error as? StreamError, StreamError.noSpaceAvailable)
        }
    }

    func testCapacityPiece() {
        let stream = MemoryStream(capacity: 4)
        let data: [UInt8] = [1, 2, 3, 4]
        assertNoThrow(try stream.write(from: data, count: 2))

        let written = try? stream.write(from: data, count: 4)
        assertEqual(written, 2)

        assertThrowsError(try stream.write(from: data, count: 4)) { error in
            assertEqual(error as? StreamError, StreamError.noSpaceAvailable)
        }
    }

    func testCapacityShift() {
        let stream = MemoryStream(capacity: 4)
        let data: [UInt8] = [1, 2, 3, 4]
        var buffer = [UInt8](repeating: 0, count: 4)

        _ = try? stream.write(from: data, count: 4)
        _ = try? stream.read(to: &buffer, count: 1)
        _ = try? stream.write(from: data, count: 1)

        let read = try? stream.read(to: &buffer, count: 4)
        assertEqual(read, 4)
        assertEqual(buffer, [2, 3, 4, 1])
    }
}
