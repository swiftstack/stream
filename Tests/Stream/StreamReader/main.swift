import Test
@testable import Stream

test.case("UntilEnd") {
    let helloBytes = [UInt8]("Hello, World!".utf8)
    let stream = ByteArrayInputStream(helloBytes)
    let bytes = try await stream.readUntilEnd()
    expect(bytes == helloBytes)
}

test.case("UntilEndAsString") {
    let helloString = "Hello, World!"
    let helloBytes = [UInt8](helloString.utf8)
    let stream = ByteArrayInputStream(helloBytes)
    let string = try await stream.readUntilEnd(as: String.self)
    expect(string == helloString)
}

test.case("ReadLine") {
    let lines = "Hello, World!\r\nHello, World!\r\n"
    let stream = ByteArrayInputStream([UInt8](lines.utf8))

    expect(try await stream.readLine() == "Hello, World!")
    expect(try await stream.readLine() == "Hello, World!")
    expect(try await stream.readLine() == nil)
}

test.run()
