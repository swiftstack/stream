import Test
@testable import Stream

// FIXME: [Concurrency] crash on m1
test("SizedBy") {
    let stream = ByteArrayOutputStream()
    try await stream.withSubStreamWriter(sizedBy: UInt16.self) { stream in
        return try await stream.write("Hello, World!")
    }
    expect(stream.bytes[..<2] == [0x00, 0x0D])
    expect(stream.bytes[2...] == [UInt8]("Hello, World!".utf8)[...])
}

test("SizedByIncludingHeader") {
    let stream = ByteArrayOutputStream()
    try await stream.withSubStreamWriter(
        sizedBy: UInt16.self,
        includingHeader: true
    ) { stream in
        return try await stream.write("Hello, World!")
    }
    expect(stream.bytes[..<2] == [0x00, 0x0F])
    expect(stream.bytes[2...] == [UInt8]("Hello, World!".utf8)[...])
}

await run()
