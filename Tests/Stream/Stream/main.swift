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

test.case("CopyBytes") {
    let input = TestStream()
    let output = TestStream()

    let written = try await input.write(from: [0,1,2,3,4,5,6,7,8,9])
    expect(written == 10)
    let copied = try await output.copyBytes(from: input, bufferSize: 3)
    expect(copied == 10)
    expect(output.storage == [0,1,2,3,4,5,6,7,8,9])
}

test.run()
