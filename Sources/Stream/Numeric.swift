extension StreamReader {
    public func parse(_ type: Int.Type) async throws -> Int? {
        let isNegative = try await consume(.hyphen)

        let result = try await read(while: { $0 >= .zero && $0 <= .nine }) {
            return Int($0)
        }
        guard let integer = result else {
            return nil
        }

        return isNegative ? -integer : integer
    }

    public func parse(_ type: Double.Type) async throws -> Double? {
        var bytes = [UInt8]()

        try await read(while: { $0 >= .zero && $0 <= .nine }) {
            bytes.append(contentsOf: $0)
        }

        if let result = try? await consume(.dot), result == true {
            bytes.append(.dot)
            try await read(while: { $0 >= .zero && $0 <= .nine }) {
                bytes.append(contentsOf: $0)
            }
        }

        return Double(String(bytes))
    }
}

extension Int {
    fileprivate init?(_ bytes: UnsafeRawBufferPointer) {
        guard bytes.count > 0 else {
            return nil
        }
        var value = 0
        for byte in bytes {
            value *= 10
            value += Int(byte - .zero)
        }
        self = value
    }
}

extension String {
    fileprivate init(_ bytes: [UInt8]) {
        if #available(macOS 11.0, iOS 14.0, *) {
            self = String(unsafeUninitializedCapacity: bytes.count) {
                _ = $0.initialize(from: bytes)
                return bytes.count
            }
        } else {
            self = String(decoding: bytes, as: UTF8.self)
        }
    }
}
