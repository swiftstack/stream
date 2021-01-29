public enum PredicateMode {
    case strict
    case untilEnd
}

public protocol StreamReader: AnyObject {
    func cache(count: Int) async throws -> Bool

    func peek() async throws -> UInt8

    func peek<T>(
        count: Int,
        body: (UnsafeRawBufferPointer) throws -> T
    ) async throws -> T

    func read<T: FixedWidthInteger>(_ type: T.Type) async throws -> T

    func read<T>(
        count: Int,
        body: (UnsafeRawBufferPointer) throws -> T
    ) async throws -> T

    func read<T>(
        mode: PredicateMode,
        while predicate: (UInt8) -> Bool,
        body: (UnsafeRawBufferPointer) throws -> T
    ) async throws -> T

    func consume(count: Int) async throws

    func consume(_ byte: UInt8) async throws -> Bool

    func consume(
        mode: PredicateMode,
        while predicate: (UInt8) -> Bool
    ) async throws
}

extension StreamReader {
    @inline(__always)
    public func read<T>(
        until byte: UInt8,
        body: (UnsafeRawBufferPointer) throws -> T) async throws -> T
    {
        return try await read(
            mode: .strict,
            while: { $0 != byte },
            body: body)
    }

    @inline(__always)
    public func readUntilEnd<T>(
        body: (UnsafeRawBufferPointer) throws -> T) async throws -> T
    {
        return try await read(
            mode: .untilEnd,
            while: { _ in true },
            body: body)
    }

    public func consume(until byte: UInt8) async throws {
        try await consume(mode: .strict, while: { $0 != byte })
    }

    @inlinable
    public func consume<T>(sequence bytes: T) async throws -> Bool
        where T: Collection, T.Element == UInt8
    {
        guard try await cache(count: bytes.count) else {
            throw StreamError.insufficientData
        }
        guard try await next(is: bytes) else {
            return false
        }
        try await consume(count: bytes.count)
        return true
    }

    @inlinable
    public func consume(set: Set<UInt8>) async throws {
        try await consume(while: set.contains)
    }

    @inlinable
    public func next<T: Collection>(is elements: T) async throws -> Bool
        where T.Element == UInt8
    {
        return try await peek(count: elements.count) { bytes in
            return bytes.elementsEqual(elements)
        }
    }
}

// MARK: untilEnd = true by default

extension StreamReader {
    @inline(__always)
    public func read<T>(
        while predicate: (UInt8) -> Bool,
        body: (UnsafeRawBufferPointer) throws -> T) async throws -> T
    {
        return try await read(mode: .untilEnd, while: predicate, body: body)
    }

    @inline(__always)
    public func consume(while predicate: (UInt8) -> Bool) async throws {
        try await consume(mode: .untilEnd, while: predicate)
    }
}

// MARK: [UInt8]

extension StreamReader {
    public func read(until byte: UInt8) async throws -> [UInt8] {
        return try await read(until: byte, body: [UInt8].init)
    }

    @inlinable
    public func read(count: Int) async throws -> [UInt8] {
        return try await read(count: count, body: [UInt8].init)
    }

    @inlinable
    public func read(
        mode: PredicateMode = .untilEnd,
        while predicate: (UInt8) -> Bool) async throws -> [UInt8]
    {
        return try await read(mode: mode, while: predicate, body: [UInt8].init)
    }
}

// MARK: read line

extension StreamReader {
    @usableFromInline
    func consumeLineEnd() async throws {
        _ = try? await consume(.cr)
        _ = try await consume(.lf)
    }

    @inlinable
    public func readLine<T>(
        body: (UnsafeRawBufferPointer) throws -> T
    ) async -> T? {
        do {
            let result: T = try await read(
                mode: .strict,
                while: { $0 != .cr && $0 != .lf },
                body: body)

            try await consumeLineEnd()
            return result
        } catch {
            return nil
        }
    }

    @inlinable
    public func readLine() async throws -> String? {
        return try await readLine(as: UTF8.self)
    }

    @inlinable
    public func readLine<T>(as encoding: T.Type) async throws -> String?
        where T: Unicode.Encoding
    {
        return await readLine { bytes in
            guard bytes.count > 0 else { return "" }
            let codeUnits = bytes.bindMemory(to: T.CodeUnit.self)
            return String(decoding: codeUnits, as: encoding)
        }
    }
}
