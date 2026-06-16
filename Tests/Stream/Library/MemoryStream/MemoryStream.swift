import Testing
@testable import Stream

@Test("MemoryStream Type")
func memoryStreamType() async throws {
    let stream = MemoryStream()
    #expect((stream as Any) is MemoryStream)
}

@Test("MemoryStream InputStream downcast")
func memoryStreamInputStreamDowncast() async throws {
    let stream = MemoryStream()
    #expect((stream as Any) is any InputStream)
}

@Test("MemoryStream OutputStream downcast")
func memoryStreamOutputStreamDowncast() async throws {
    let stream = MemoryStream()
    #expect((stream as Any) is any OutputStream)
}

@Test("MemoryStream initial size")
func memoryStreamInitialSize() async throws {
    let stream = MemoryStream()
    #expect(stream.capacity == 0)
    #expect(stream.position == 0)
    #expect(stream.remain == 0)
}

@Test("MemoryStream write empty array")
func memoryStreamWriteEmptyArray() async throws {
    let stream = MemoryStream()
    let written = try stream.write(from: [UInt8](), byteCount: 0)
    #expect(written == 0)
}

@Test("MemoryStream read from empty stream")
func memoryStreamReadFromEmptyStream() async throws {
    let stream = MemoryStream()
    var buffer: [UInt8] = [0]

    let read = try stream.read(to: &buffer, byteCount: 1)
    #expect(read == 0)
}

@Test("MemoryStream seek")
func memoryStreamSeek() async throws {
    let stream = MemoryStream(capacity: 4)
    #expect((stream as Any) is any Seekable)
    #expect(stream.position == 0)
    #expect(stream.remain == 4)

    _ = try stream.write(from: [1, 2, 3, 4], byteCount: 4)
    #expect(stream.position == 4)
    #expect(stream.remain == 0)

    try stream.seek(to: 1, from: .begin)
    #expect(stream.position == 1)
    #expect(stream.remain == 3)

    try stream.seek(to: 2, from: .current)
    #expect(stream.position == 3)
    #expect(stream.remain == 1)

    try stream.seek(to: -4, from: .end)
    #expect(stream.position == 0)
    #expect(stream.remain == 4)

    #expect(throws: StreamError.invalidSeekOffset) {
        try stream.seek(to: -1, from: .begin)
    }

    #expect(throws: StreamError.invalidSeekOffset) {
        try stream.seek(to: 5, from: .begin)
    }

    #expect(throws: StreamError.invalidSeekOffset) {
        try stream.seek(to: -1, from: .current)
    }

    #expect(throws: StreamError.invalidSeekOffset) {
        try stream.seek(to: 5, from: .current)
    }

    #expect(throws: StreamError.invalidSeekOffset) {
        try stream.seek(to: 1, from: .end)
    }

    #expect(throws: StreamError.invalidSeekOffset) {
        try stream.seek(to: -5, from: .end)
    }
}

@Test("MemoryStream write")
func memoryStreamWrite() async throws {
    let stream = MemoryStream(capacity: 4)
    let data: [UInt8] = [1, 2, 3, 4]

    let written = try stream.write(from: data, byteCount: 4)
    #expect(written == 4)

    var buffer = [UInt8](repeating: 0, count: 4)
    try stream.seek(to: 0, from: .begin)
    _ = try stream.read(to: &buffer, byteCount: 4)
    #expect(buffer == [1, 2, 3, 4])

    buffer = [UInt8](repeating: 0, count: 4)
    try stream.seek(to: 0, from: .begin)

    let writtenFirst = try stream.write(from: data, byteCount: 2)
    #expect(writtenFirst == 2)
    try stream.seek(to: 0, from: .begin)
    _ = try stream.read(to: &buffer, byteCount: 2)
    #expect(buffer == [1, 2, 0, 0])

    try stream.seek(to: -2, from: .end)
    let writtenLast = try stream.write(from: [UInt8](data[2...]), byteCount: 2)
    #expect(writtenLast == 2)
    try stream.seek(to: -2, from: .end)
    _ = try stream.read(to: &buffer[2], byteCount: 2)
    #expect(buffer == data)
}

@Test("MemoryStream read")
func memoryStreamRead() async throws {
    let stream = MemoryStream(capacity: 4)
    let data: [UInt8] = [1, 2, 3, 4]
    _ = try stream.write(from: data, byteCount: 4)

    var buffer = [UInt8](repeating: 0, count: 4)
    try stream.seek(to: 0, from: .begin)

    #expect(try stream.read(to: &buffer, byteCount: 4) == 4)
    #expect(buffer == data)
    #expect(stream.position == 4)
    #expect(stream.remain == 0)

    buffer = [UInt8](repeating: 0, count: 4)
    try stream.seek(to: 0, from: .begin)

    #expect(try stream.read(to: &buffer, byteCount: 2) == 2)
    #expect(buffer == [1, 2, 0, 0])
    #expect(stream.position == 2)
    #expect(stream.remain == 2)

    #expect(try stream.read(to: &buffer[2], byteCount: 2) == 2)
    #expect(buffer == data)
    #expect(stream.position == 4)
    #expect(stream.remain == 0)
}

@Test("MemoryStream reallocate")
func memoryStreamReallocate() async throws {
    let stream = MemoryStream()
    let data: [UInt8] = [1, 2, 3, 4, 5, 6, 7, 8]

    #expect(stream.capacity == 0)
    #expect(stream.position == 0)

    _ = try stream.write(from: data, byteCount: data.count)
    #expect(stream.capacity == 256)
    #expect(stream.position == 8)
    #expect(stream.remain == 248)

    let data300 = [UInt8](repeating: 111, count: 300)

    _ = try stream.write(from: data300, byteCount: data300.count)
    #expect(stream.capacity == 1024)
    #expect(stream.position == 308)
    #expect(stream.remain == 716)

    var buffer = [UInt8](repeating: 0, count: 308)
    try stream.seek(to: 0, from: .begin)
    _ = try stream.read(to: &buffer, byteCount: buffer.count)
    #expect(buffer == [1, 2, 3, 4, 5, 6, 7, 8] + data300)
    #expect(stream.capacity == 1024)
    #expect(stream.position == 308)
    #expect(stream.remain == 716)
}

@Test("MemoryStream capacity")
func memoryStreamCapacity() async throws {
    let stream = MemoryStream(capacity: 4)
    let data: [UInt8] = [1, 2, 3, 4]
    _ = try stream.write(from: data, byteCount: 2)

    #expect(throws: StreamError.notEnoughSpace) {
        try stream.write(data)
    }
}

@Test("MemoryStream trivial")
func memoryStreamTrivial() async throws {
    let stream = MemoryStream()
    var buffer = [UInt8](repeating: 0, count: 8)

    _ = try stream.write(0x0102030405060708)
    try stream.seek(to: 0, from: .begin)
    #expect(try stream.read(to: &buffer, byteCount: 8) == 8)
    #expect(buffer == [1, 2, 3, 4, 5, 6, 7, 8])

    try stream.seek(to: 0, from: .begin)
    try stream.write(Int.max)
    try stream.write(Int8.max)
    try stream.write(Int16.max)
    try stream.write(Int32.max)
    try stream.write(Int64.max)
    try stream.write(UInt.max)
    try stream.write(UInt8.max)
    try stream.write(UInt16.max)
    try stream.write(UInt32.max)
    try stream.write(UInt64.max)

    try stream.seek(to: 0, from: .begin)
    #expect(try stream.read(Int.self) == Int.max)
    #expect(try stream.read(Int8.self) == Int8.max)
    #expect(try stream.read(Int16.self) == Int16.max)
    #expect(try stream.read(Int32.self) == Int32.max)
    #expect(try stream.read(Int64.self) == Int64.max)
    #expect(try stream.read(UInt.self) == UInt.max)
    #expect(try stream.read(UInt8.self) == UInt8.max)
    #expect(try stream.read(UInt16.self) == UInt16.max)
    #expect(try stream.read(UInt32.self) == UInt32.max)
    #expect(try stream.read(UInt64.self) == UInt64.max)
}

@Test("MemoryStream buffer")
func memoryStreamBuffer() async throws {
    let stream = MemoryStream(capacity: 4)
    let data: [UInt8] = [1, 2, 3, 4]

    _ = try stream.write(from: data, byteCount: 4)
    #expect([1, 2, 3, 4] == [UInt8](stream.buffer))

    var buffer = [UInt8](repeating: 0, count: 1)
    _ = try stream.read(to: &buffer, byteCount: 4)
    #expect([1, 2, 3, 4] == [UInt8](stream.buffer))
}

@Test("MemoryStream byte")
func memoryStreamByte() async throws {
    let stream = MemoryStream(reservingCapacity: 0)

    #expect(throws: Never.self) {
        _ = try stream.write(UInt8(42))
    }
}
