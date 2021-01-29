import Test
@testable import Stream

fileprivate class TestStream: InputStream {
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

test.case("Read") {
    let stream = BufferedInputStream(
        baseStream: TestStream(),
        capacity: 1)
    expect(stream.expandable == true)
    expect(stream.allocated == 1)

    var buffer = try await stream.read(count: 10)
    expect([UInt8](buffer) == [UInt8](repeating: 1, count: 10))
    expect(stream.readPosition == stream.storage + 10)
    // allocated(1) < requested,
    // so we reserve requested(10) * 2
    expect(stream.writePosition == stream.storage + 20)

    // stil have buffered data
    buffer = try await stream.read(count: 10)
    expect([UInt8](buffer) == [UInt8](repeating: 1, count: 10))
    expect(stream.readPosition == stream.storage)
    expect(stream.writePosition == stream.storage)

    // buffer is empty so another read
    // from the source stream initiated
    buffer = try await stream.read(count: 5)
    expect([UInt8](buffer) == [UInt8](repeating: 2, count: 5))
    expect(stream.readPosition == stream.storage + 5)
    expect(stream.writePosition == stream.storage + 20)

    // stil have 15 bytes
    // reallocate x2 because the content is > capacity / 2
    buffer = try await stream.read(count: 20)
    expect(
        [UInt8](buffer)
        ==
        [UInt8](repeating: 2, count: 15)
        +
        [UInt8](repeating: 3, count: 5))
    expect(stream.readPosition == stream.storage + 20)
    expect(stream.writePosition == stream.storage + 40)

    buffer = try await stream.read(count: 10)
    expect([UInt8](buffer) == [UInt8](repeating: 3, count: 10))
    expect(stream.readPosition == stream.storage + 30)
    expect(stream.writePosition == stream.storage + 40)
    expect(stream.allocated == 40)

    // shift << the content because it's < capacity / 2
    buffer = try await stream.read(count: 20)
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

test.case("ReadReservingCapacity") {
    let stream = BufferedInputStream(
        baseStream: TestStream(),
        capacity: 10)
    expect(stream.expandable == true)
    expect(stream.allocated == 10)

    var buffer = try await stream.read(count: 10)
    expect([UInt8](buffer) == [UInt8](repeating: 1, count: 10))
    expect(stream.readPosition == stream.storage)
    expect(stream.writePosition == stream.storage)

    buffer = try await stream.read(count: 10)
    expect([UInt8](buffer) == [UInt8](repeating: 2, count: 10))
    expect(stream.readPosition == stream.storage)
    expect(stream.writePosition == stream.storage)
}

test.case("ReadFixedCapacity") {
    let stream = BufferedInputStream(
        baseStream: TestStream(),
        capacity: 10,
        expandable: false)
    expect(stream.expandable == false)
    expect(stream.allocated == 10)

    var buffer = try await stream.read(count: 10)
    expect([UInt8](buffer) == [UInt8](repeating: 1, count: 10))
    expect(stream.readPosition == stream.storage)
    expect(stream.writePosition == stream.storage)

    expect(throws: StreamError.notEnoughSpace) {
        try await stream.read(count: 11)
    }

    expect(stream.readPosition == stream.storage)
    expect(stream.writePosition == stream.storage)

    buffer = try await stream.read(count: 2)
    expect([UInt8](buffer) == [UInt8](repeating: 2, count: 2))
    expect(stream.readPosition == stream.storage + 2)
    expect(stream.writePosition == stream.storage + 10)

    // shift the rest and fill with another read
    buffer = try await stream.read(count: 9)
    expect([UInt8](buffer) == [UInt8](repeating: 2, count: 8) + [3])
    expect(stream.readPosition == stream.storage + 9)
    expect(stream.writePosition == stream.storage + 10)
}

test.case("ReadByte") {
    let stream = BufferedInputStream(
        baseStream: TestStream(byteLimit: 4),
        capacity: 2)

    expect(try await stream.read(UInt8.self) == 1)
    expect(try await stream.read(UInt8.self) == 1)
    expect(try await stream.read(UInt8.self) == 2)
    expect(try await stream.read(UInt8.self) == 2)

    expect(throws: StreamError.insufficientData) {
        try await stream.read(UInt8.self)
    }
}

test.case("ReadWhile") {
    let stream = BufferedInputStream(
        baseStream: TestStream(),
        capacity: 5)
    expect(stream.expandable == true)
    expect(stream.allocated == 5)

    let buffer = try await stream.read(while: { $0 != 3 })
    expect(
        [UInt8](buffer)
        ==
        [UInt8](repeating: 1, count: 5)
        +
        [UInt8](repeating: 2, count: 7))
    expect(stream.readPosition == stream.storage + 12)
    expect(stream.writePosition == stream.storage + 26)
}

test.case("ReadWhileUntilEnd") {
    let stream = BufferedInputStream(
        baseStream: TestStream(byteLimit: 5),
        capacity: 5)

    expect(throws: StreamError.insufficientData) {
        try await stream.read(mode: .strict, while: { $0 == 1 })
    }
    // NOTE: does not consume bytes on error
    expect(stream.buffered == 5)

    _ = try await stream.read(mode: .untilEnd, while: { $0 == 1 })
}

test.case("ReadUntil") {
    let stream = BufferedInputStream(
        baseStream: TestStream(),
        capacity: 5)
    expect(stream.expandable == true)
    expect(stream.allocated == 5)

    try await stream.read(until: 3) { buffer in
        let expected =
            [UInt8](repeating: 1, count: 5)
            +
            [UInt8](repeating: 2, count: 7)
        expect([UInt8](buffer) == expected)
    }
    expect(stream.readPosition == stream.storage + 12)
    expect(stream.writePosition == stream.storage + 26)
}

test.case("Peek") {
    let stream = BufferedInputStream(
        baseStream: TestStream(byteLimit: 10),
        capacity: 10,
        expandable: false)
    expect(try await stream.feed() == true)
    expect(stream.readPosition == stream.storage)
    expect(stream.writePosition == stream.storage + 10)

    expect(throws: StreamError.notEnoughSpace) {
        try await stream.cache(count: 15)
    }

    expect(try await stream.cache(count: 5) == true)
    expect(try await stream.next(is: [UInt8](repeating: 1, count: 5)))
    expect(stream.readPosition == stream.storage)
    expect(stream.writePosition == stream.storage + 10)

    expect(try await stream.read(count: 10).count == 10)
    expect(try await stream.cache(count: 5) == false)
}

test.case("Consume") {
    let stream = BufferedInputStream(
        baseStream: TestStream(),
        capacity: 10)
    expect(stream.readPosition == stream.storage)
    expect(stream.writePosition == stream.storage)

    try await stream.consume(count: 5)

    expect(stream.readPosition == stream.storage + 5)
    expect(stream.writePosition == stream.storage + 10)

    try await stream.consume(count: 5)

    expect(stream.readPosition == stream.storage)
    expect(stream.writePosition == stream.storage)

    let buffer = try await stream.read(count: 5)
    expect([UInt8](buffer) == [UInt8](repeating: 2, count: 5))
    expect(stream.readPosition == stream.storage + 5)
    expect(stream.writePosition == stream.storage + 10)
}

test.case("ConsumeNotExpandable") {
    let stream = BufferedInputStream(
        baseStream: TestStream(),
        capacity: 10,
        expandable: false)
    expect(stream.readPosition == stream.storage)
    expect(stream.writePosition == stream.storage)
    expect(stream.expandable == false)
    expect(stream.allocated == 10)

    try await stream.consume(count: 15)

    expect(stream.readPosition == stream.storage + 5)
    expect(stream.writePosition == stream.storage + 10)
    expect(stream.expandable == false)
    expect(stream.allocated == 10)

    let buffer = try await stream.read(count: 5)
    expect([UInt8](buffer) == [UInt8](repeating: 2, count: 5))
    expect(stream.readPosition == stream.storage)
    expect(stream.writePosition == stream.storage)
}

test.case("ConsumeByte") {
    let stream = BufferedInputStream(baseStream: TestStream(byteLimit: 2))
    expect(stream.buffered == 0)

    expect(try await stream.consume(UInt8(1)) == true)
    expect(stream.buffered == 1)

    expect(try await stream.consume(UInt8(2)) == false)
    expect(stream.buffered == 1)

    expect(try await stream.consume(UInt8(1)) == true)
    expect(stream.buffered == 0)

    expect(throws: StreamError.insufficientData) {
        try await stream.consume(1)
    }
}

test.case("ConsumeWhile") {
    let stream = BufferedInputStream(
        baseStream: TestStream(),
        capacity: 2)
    expect(stream.readPosition == stream.storage)
    expect(stream.writePosition == stream.storage)
    expect(stream.allocated == 2)
    expect(stream.buffered == 0)

    try await stream.consume(while: { $0 == 1 || $0 == 2 })

    expect(stream.readPosition == stream.storage)
    expect(stream.writePosition == stream.storage + 2)
    expect(stream.allocated == 2)
    expect(stream.buffered == 2)

    let buffer = try await stream.read(count: 10)
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

test.case("ConsumeUntil") {
    let stream = BufferedInputStream(
        baseStream: TestStream(),
        capacity: 2)
    expect(stream.readPosition == stream.storage)
    expect(stream.writePosition == stream.storage)
    expect(stream.allocated == 2)
    expect(stream.buffered == 0)

    try await stream.consume(until: 3)

    expect(stream.readPosition == stream.storage)
    expect(stream.writePosition == stream.storage + 2)
    expect(stream.allocated == 2)
    expect(stream.buffered == 2)

    let buffer = try await stream.read(count: 10)
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

test.case("ConsumeEmpty") {
    let stream = BufferedInputStream(baseStream: InputByteStream([]))
    expect(throws: StreamError.insufficientData) {
        try await stream.consume(count: 1)
    }
}

test.case("FeedLessThanReadCount") {
    let stream = BufferedInputStream(
        baseStream: TestStream(byteLimit: 20),
        capacity: 10)
    expect(stream.readPosition == stream.storage)
    expect(stream.writePosition == stream.storage)

    let buffer = try await stream.read(count: 20)
    expect([UInt8](buffer) == [UInt8](repeating: 1, count: 20))
}

test.case("AdvancePositionBeforeCallback") {
    let stream = BufferedInputStream(
        baseStream: InputByteStream([0,1,2,3,4,5,6,7,8,9]))
    try await stream.readUntilEnd { bytes in
        expect(stream.readPosition == stream.writePosition)
    }
}

test.case("ReadLine") {
    let stream = BufferedInputStream(
        baseStream: InputByteStream([UInt8]("line1\r\nline2\n".utf8)))
    expect(try await stream.readLine() == "line1")
    expect(try await stream.readLine() == "line2")
}

test.run()
