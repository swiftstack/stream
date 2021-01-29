import Test
@testable import Stream

test.case("InputByteStream") {
    let inputStream  = InputByteStream([])
    var buffer = [UInt8]()
    expect(try inputStream.read(to: &buffer, byteCount: 0) == 0)
}

test.case("OutputByteStream") {
    let outputStream  = OutputByteStream()
    let bytes = [UInt8]()
    expect(try outputStream.write(from: bytes, byteCount: 0) == 0)
}

test.case("OutputByteStream Numeric") {
    let outputStream  = OutputByteStream()

    try outputStream.write(Int(-1))
    try outputStream.write(Int8(-2))
    try outputStream.write(Int16(-3))
    try outputStream.write(Int32(-4))
    try outputStream.write(Int64(-5))
    try outputStream.write(UInt(1))
    try outputStream.write(UInt8(2))
    try outputStream.write(UInt16(3))
    try outputStream.write(UInt32(4))
    try outputStream.write(UInt64(5))

    let inputStream  = InputByteStream(outputStream.bytes)

    expect(try inputStream.read(Int.self) == -1)
    expect(try inputStream.read(Int8.self) == -2)
    expect(try inputStream.read(Int16.self) == -3)
    expect(try inputStream.read(Int32.self) == -4)
    expect(try inputStream.read(Int64.self) == -5)
    expect(try inputStream.read(UInt.self) == 1)
    expect(try inputStream.read(UInt8.self) == 2)
    expect(try inputStream.read(UInt16.self) == 3)
    expect(try inputStream.read(UInt32.self) == 4)
    expect(try inputStream.read(UInt64.self) == 5)
}

test.case("OutputByteStream CopyBytes") {
    let input = InputByteStream([0,1,2,3,4,5,6,7,8,9])
    let output = OutputByteStream()

    let copied = try await output.copyBytes(from: input, bufferSize: 3)
    expect(copied == 10)
    expect(output.bytes == [0,1,2,3,4,5,6,7,8,9])
}

test.case("OutputByteStream AdvancePositionBeforeCallback") {
    let input = InputByteStream([0,1,2,3,4,5,6,7,8,9])
    try await input.readUntilEnd { bytes in
        expect(input.position == input.bytes.count)
    }
}

test.run()
