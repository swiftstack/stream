import Test
@testable import Stream

test.case("Stream") {
    let testStream  = TestStream()
    let stream = testStream as Stream
    var bytes = [UInt8]()
    _ = try await stream.read(to: &bytes, byteCount: 0)
    _ = try await stream.write(from: bytes, byteCount: 0)
}

test.case("InputStream") {
    let testStream  = TestStream()
    let inputStream = testStream as InputStream
    var buffer = [UInt8]()
    _ = try await inputStream.read(to: &buffer, byteCount: 0)
}

test.case("OutputStream") {
    let testStream  = TestStream()
    let outputStream = testStream as OutputStream
    let bytes = [UInt8]()
    _ = try await outputStream.write(from: bytes, byteCount: 0)
}

test.run()
