public final class AllowedBytes {
    @usableFromInline
    let buffer: UnsafeBufferPointer<Bool>

    public init(byteSet set: Set<UInt8>) {
        let buffer = UnsafeMutableBufferPointer<Bool>.allocate(capacity: 256)
        buffer.initialize(repeating: false)
        for byte in set {
            buffer[Int(byte)] = true
        }
        self.buffer = UnsafeBufferPointer(buffer)
    }

    public init(asciiTable table: AllowedASCII) {
        let buffer = UnsafeMutableBufferPointer<Bool>.allocate(capacity: 256)
        buffer.initialize(repeating: false)

        var copy = table
        let pointer = UnsafeMutableRawPointer(mutating: &copy)
            .assumingMemoryBound(to: Bool.self)
        let asciiBuffer = UnsafeBufferPointer(start: pointer, count: 128)
        _ = buffer.initialize(from: asciiBuffer)

        self.buffer = UnsafeBufferPointer(buffer)
    }

    deinit {
        buffer.deallocate()
    }
}

extension StreamReader {
    @inline(__always)
    public func read<T>(
        allowedBytes: AllowedBytes,
        body: (UnsafeRawBufferPointer) throws -> T) throws -> T
    {
        let buffer = allowedBytes.buffer
        return try read(
            mode: .untilEnd,
            while: { buffer[Int($0)] },
            body: body)
    }

    @inline(__always)
    public func read(allowedBytes: AllowedBytes) throws -> [UInt8] {
        let buffer = allowedBytes.buffer
        return try read(while: { buffer[Int($0)] })
    }
}

public typealias AllowedASCII = (
    Bool, Bool, Bool, Bool, Bool, Bool, Bool, Bool,
    Bool, Bool, Bool, Bool, Bool, Bool, Bool, Bool,
    Bool, Bool, Bool, Bool, Bool, Bool, Bool, Bool,
    Bool, Bool, Bool, Bool, Bool, Bool, Bool, Bool,
    Bool, Bool, Bool, Bool, Bool, Bool, Bool, Bool,
    Bool, Bool, Bool, Bool, Bool, Bool, Bool, Bool,
    Bool, Bool, Bool, Bool, Bool, Bool, Bool, Bool,
    Bool, Bool, Bool, Bool, Bool, Bool, Bool, Bool,
    Bool, Bool, Bool, Bool, Bool, Bool, Bool, Bool,
    Bool, Bool, Bool, Bool, Bool, Bool, Bool, Bool,
    Bool, Bool, Bool, Bool, Bool, Bool, Bool, Bool,
    Bool, Bool, Bool, Bool, Bool, Bool, Bool, Bool,
    Bool, Bool, Bool, Bool, Bool, Bool, Bool, Bool,
    Bool, Bool, Bool, Bool, Bool, Bool, Bool, Bool,
    Bool, Bool, Bool, Bool, Bool, Bool, Bool, Bool,
    Bool, Bool, Bool, Bool, Bool, Bool, Bool, Bool)
