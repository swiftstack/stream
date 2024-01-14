import Test
@testable import Stream

test("LimitedBy") {
    let stream = ByteArrayInputStream("Hello, World!") as any StreamReader
    let hello = try await stream.withSubStreamReader(limitedBy: 5) { stream in
        return try await stream.readUntilEnd(as: String.self)
    }
    try await stream.consume(count: 2)
    let world = try await stream.readUntilEnd(as: String.self)
    expect(hello == "Hello")
    expect(world == "World!")
}

test("SizedBy") {
    let bytes = [0x00, 0x05] + [UInt8]("Hello, World!".utf8)
    let stream = ByteArrayInputStream(bytes) as any StreamReader
    let hello = try await stream.withSubStreamReader(sizedBy: UInt16.self)
    { stream in
        return try await stream.readUntilEnd(as: String.self)
    }
    try await stream.consume(count: 2)
    let world = try await stream.readUntilEnd(as: String.self)
    expect(hello == "Hello")
    expect(world == "World!")
}

test("SizedByIncludingHeader") {
    let bytes = [0x00, 0x07] + [UInt8]("Hello, World!".utf8)
    let stream = ByteArrayInputStream(bytes) as any StreamReader
    let hello = try await  stream.withSubStreamReader(
        sizedBy: UInt16.self,
        includingHeader: true)
    { stream in
        return try await stream.readUntilEnd(as: String.self)
    }
    try await stream.consume(count: 2)
    let world = try await stream.readUntilEnd(as: String.self)
    expect(hello == "Hello")
    expect(world == "World!")
}

await run()
