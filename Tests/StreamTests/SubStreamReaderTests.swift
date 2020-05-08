import Test
@testable import Stream

class SubStreamReaderTests: TestCase {
    func testLimitedBy() throws {
        let stream = InputByteStream([UInt8]("Hello, World!".utf8))
        let hello = try stream.withSubStreamReader(limitedBy: 5) { stream in
            return try stream.readUntilEnd(as: String.self)
        }
        try stream.consume(count: 2)
        let world = try stream.readUntilEnd(as: String.self)
        expect(hello == "Hello")
        expect(world == "World!")
    }

    func testSizedBy() throws {
        let bytes = [0x00, 0x05] + [UInt8]("Hello, World!".utf8)
        let stream = InputByteStream(bytes)
        let hello = try stream.withSubStreamReader(sizedBy: UInt16.self)
        { stream in
            return try stream.readUntilEnd(as: String.self)
        }
        try stream.consume(count: 2)
        let world = try stream.readUntilEnd(as: String.self)
        expect(hello == "Hello")
        expect(world == "World!")
    }

    func testSizedByIncludingHeader() throws {
        let bytes = [0x00, 0x07] + [UInt8]("Hello, World!".utf8)
        let stream = InputByteStream(bytes)
        let hello = try stream.withSubStreamReader(
            sizedBy: UInt16.self,
            includingHeader: true)
        { stream in
            return try stream.readUntilEnd(as: String.self)
        }
        try stream.consume(count: 2)
        let world = try stream.readUntilEnd(as: String.self)
        expect(hello == "Hello")
        expect(world == "World!")
    }
}
