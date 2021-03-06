import Test
@testable import Stream

test.case("InputByteStream") {
    let inputStream  = InputByteStream([])
    var buffer = [UInt8]()
    expect(try inputStream.read(to: &buffer, byteCount: 0) == 0)
}

test.case("InputByteStream advance position before callback") {
    let input = InputByteStream([0,1,2,3,4,5,6,7,8,9])
    try await input.readUntilEnd { bytes in
        expect(input.position == input.bytes.count)
    }
}

test.run()
