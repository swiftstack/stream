import Test
import Stream

test.case("Int") {
    expect(try await InputByteStream("42").parse(Int.self) == 42)
    expect(try await InputByteStream("3.14").parse(Int.self) == 3)
    expect(try await InputByteStream("-42").parse(Int.self) == -42)
}

test.case("Double") {
    expect(try await InputByteStream("0.1").parse(Double.self) == 0.1)
    expect(try await InputByteStream("1.0").parse(Double.self) == 1.0)
    expect(try await InputByteStream("0.7").parse(Double.self) == 0.7)
    expect(try await InputByteStream("3.14").parse(Double.self) == 3.14)
    expect(try await InputByteStream("42").parse(Double.self) == 42)
    expect(try await InputByteStream("42.").parse(Double.self) == 42)
}

test.run()
