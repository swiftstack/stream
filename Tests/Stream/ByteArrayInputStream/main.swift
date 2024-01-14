import Test
@testable import Stream

test("ByteArrayInputStream") {
    let inputStream  = ByteArrayInputStream([])
    var buffer = [UInt8]()
    expect(try inputStream.read(to: &buffer, byteCount: 0) == 0)
}

test("ByteArrayInputStream advance position before callback") {
    let input = ByteArrayInputStream([0,1,2,3,4,5,6,7,8,9])
    try await input.readUntilEnd { bytes in
        expect(input.position == input.bytes.count)
    }
}

await run()
