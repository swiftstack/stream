import Testing
import Stream

@Test("Numeric Int")
func int() async throws {
    #expect(try await MemoryStream("42").parse(Int.self) == 42)
//    #expect(try await MemoryStream("3.14").parse(Int.self) == 3)
//    #expect(try await MemoryStream("-42").parse(Int.self) == -42)
}

@Test("Numeric Double")
func double() async throws {
    #expect(try await MemoryStream("0.1").parse(Double.self) == 0.1)
    #expect(try await MemoryStream("1.0").parse(Double.self) == 1.0)
    #expect(try await MemoryStream("0.7").parse(Double.self) == 0.7)
    #expect(try await MemoryStream("3.14").parse(Double.self) == 3.14)
    #expect(try await MemoryStream("42").parse(Double.self) == 42)
    #expect(try await MemoryStream("42.").parse(Double.self) == 42)
}
