import Test
@testable import Stream

test.case("BufferedOutputStream") {
    let byteStream = ByteArrayOutputStream()
    let stream = BufferedOutputStream(baseStream: byteStream, capacity: 10)
    expect(stream.allocated == 10)
    expect(stream.buffered == 0)

    expect(try await stream.write(from: [0,1,2,3,4]) == 5)
    expect(stream.buffered == 5)
    expect(try await stream.write(from: [5,6]) == 2)
    expect(stream.buffered == 7)
    expect(try await stream.write(from: [7,8,9]) == 3)
    expect(stream.buffered == 0)

    expect(byteStream.bytes == [0,1,2,3,4,5,6,7,8,9])
    byteStream.bytes = []

    expect(try await stream.write(from: [0,1,2,3,4,5,6,7,8]) == 9)
    expect(stream.buffered == 9)
    expect(try await stream.write(from: [9,0,1,2,3,4,5,6,7,8,9,10,11]) == 13)
    expect(stream.buffered == 0)

    expect(byteStream.bytes == [
        0,1,2,3,4,5,6,7,8,
        9,0,1,2,3,4,5,6,7,8,9,10,11
    ])
    byteStream.bytes = []

    expect(try await stream.write(from: [0,1,2,3,4,5,6,7,8]) == 9)
    expect(stream.buffered == 9)
    expect(try await stream.write(from: [9,0,1]) == 3)
    expect(stream.buffered == 2)

    expect(byteStream.bytes == [0,1,2,3,4,5,6,7,8,9])
    byteStream.bytes = []

    expect(try await stream.flush() == ())
    expect(stream.buffered == 0)

    expect(byteStream.bytes == [0,1])
}

test.case("BufferedOutputStreamDefaultCapacity") {
    let stream = BufferedOutputStream(baseStream: ByteArrayOutputStream())
    expect(stream.allocated == 256)
    expect(stream.buffered == 0)
}

test.run()
