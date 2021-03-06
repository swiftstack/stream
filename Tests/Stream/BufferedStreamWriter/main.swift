import Test
@testable import Stream

test.case("WriteByte") {
    let stream = ByteArrayOutputStream()
    let output = BufferedOutputStream(baseStream: stream, capacity: 5)

    try await output.write(UInt8(42))
    try await output.flush()

    expect(stream.bytes == [42])
}

test.run()
