import Test
@testable import Stream

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

test("BufferedInputStream") {
    let baseStream = TestInputStreamSequence()
    let stream = BufferedInputStream(baseStream: baseStream, capacity: 10)
    expect(stream.allocated == 10)
    expect(stream.buffered == 0)

    func read(count: Int) async throws -> [UInt8] {
        var buffer = [UInt8](repeating: 0, count: count)
        expect(try await stream.read(to: &buffer, byteCount: count) == count)
        return buffer
    }

    expect(try await read(count: 5) == [0,1,2,3,4])
    expect(stream.buffered == 5)
    expect(try await read(count: 2) == [5,6])
    expect(stream.buffered == 3)
    expect(try await read(count: 13) == [7,8,9,0,1,2,3,4,5,6,7,8,9])
    expect(stream.buffered == 0)

    expect(try await read(count: 10) == [0,1,2,3,4,5,6,7,8,9])
    expect(stream.buffered == 0)

    expect(try await read(count: 13) == [0,1,2,3,4,5,6,7,8,9,10,11,12])
    expect(stream.buffered == 0)

    expect(try await read(count: 9) == [0,1,2,3,4,5,6,7,8])
    expect(stream.buffered == 1)
    expect(try await read(count: 13) == [9,0,1,2,3,4,5,6,7,8,9,10,11])
    expect(stream.buffered == 0)
    // test if stream resets if drained
    stream.clear()
    expect(stream.buffered == 0)
    _ = try await read(count: 1)
    expect(stream.buffered == 9)
    _ = try await read(count: 9)
    expect(stream.buffered == 0)
    expect(stream.readPosition == stream.storage)
    expect(stream.writePosition == stream.storage)
}

test("BufferedInputStreamDefaultCapacity") {
    let stream = BufferedInputStream(baseStream: ByteArrayInputStream([]))
    expect(stream.allocated == 256)
    expect(stream.buffered == 0)
}

await run()
