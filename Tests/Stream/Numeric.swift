import Testing
import Stream

@Test("Numeric Int")
func int() async throws {
    #expect(try await ByteArrayInputStream("42").parse(Int.self) == 42)
    #expect(try await ByteArrayInputStream("3.14").parse(Int.self) == 3)
    #expect(try await ByteArrayInputStream("-42").parse(Int.self) == -42)
}

@Test("Numeric Double")
func double() async throws {
    #expect(try await ByteArrayInputStream("0.1").parse(Double.self) == 0.1)
    #expect(try await ByteArrayInputStream("1.0").parse(Double.self) == 1.0)
    #expect(try await ByteArrayInputStream("0.7").parse(Double.self) == 0.7)
    #expect(try await ByteArrayInputStream("3.14").parse(Double.self) == 3.14)
    #expect(try await ByteArrayInputStream("42").parse(Double.self) == 42)
    #expect(try await ByteArrayInputStream("42.").parse(Double.self) == 42)
}
