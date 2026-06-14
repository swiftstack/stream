public extension MemoryStream {
    convenience init(_ bytes: [UInt8]) {
        self.init(capacity: bytes.count)
        try? self.write(bytes)
        try? self.seek(to: 0, from: .begin)
    }

    convenience init(_ string: String) {
        self.init(capacity: string.utf8.count)
        try? self.write([UInt8](string.utf8))
        try? self.seek(to: 0, from: .begin)
    }
}
