public enum PredicateMode {
    case strict
    case untilEnd
}

public protocol StreamReader: class {
    func cache(count: Int) throws -> Bool

    func peek() throws -> UInt8

    func peek<T>(
        count: Int,
        body: (UnsafeRawBufferPointer) throws -> T
    ) throws -> T

    func read<T: FixedWidthInteger>(_ type: T.Type) throws -> T

    func read<T>(
        count: Int,
        body: (UnsafeRawBufferPointer) throws -> T
    ) throws -> T

    func read<T>(
        mode: PredicateMode,
        while predicate: (UInt8) -> Bool,
        body: (UnsafeRawBufferPointer) throws -> T
    ) throws -> T

    func consume(count: Int) throws

    func consume(_ byte: UInt8) throws -> Bool

    func consume(
        mode: PredicateMode,
        while predicate: (UInt8) -> Bool
    ) throws
}

extension StreamReader {
    @inline(__always)
    public func read<T>(
        until byte: UInt8,
        body: (UnsafeRawBufferPointer) throws -> T) throws -> T
    {
        return try read(
            mode: .strict,
            while: { $0 != byte },
            body: body)
    }

    @inline(__always)
    public func readUntilEnd<T>(
        body: (UnsafeRawBufferPointer) throws -> T) throws -> T
    {
        return try read(
            mode: .untilEnd,
            while: { _ in true },
            body: body)
    }

    public func consume(until byte: UInt8) throws {
        try consume(mode: .strict, while: { $0 != byte })
    }

    @inlinable
    public func consume<T>(sequence bytes: T) throws -> Bool
        where T: Collection, T.Element == UInt8
    {
        guard try cache(count: bytes.count) else {
            throw StreamError.insufficientData
        }
        guard try next(is: bytes) else {
            return false
        }
        try consume(count: bytes.count)
        return true
    }

    @inlinable
    public func next<T: Collection>(is elements: T) throws -> Bool
        where T.Element == UInt8
    {
        return try peek(count: elements.count) { bytes in
            return bytes.elementsEqual(elements)
        }
    }
}

// MARK: untilEnd = true by default

extension StreamReader {
    @inline(__always)
    public func read<T>(
        while predicate: (UInt8) -> Bool,
        body: (UnsafeRawBufferPointer) throws -> T) throws -> T
    {
        return try read(mode: .untilEnd, while: predicate, body: body)
    }

    @inline(__always)
    public func consume(while predicate: (UInt8) -> Bool) throws {
        try consume(mode: .untilEnd, while: predicate)
    }
}

// MARK: [UInt8]

extension StreamReader {
    public func read(until byte: UInt8) throws -> [UInt8] {
        return try read(until: byte, body: [UInt8].init)
    }

    @inlinable
    public func read(count: Int) throws -> [UInt8] {
        return try read(count: count, body: [UInt8].init)
    }

    @inlinable
    public func read(
        mode: PredicateMode = .untilEnd,
        while predicate: (UInt8) -> Bool) throws -> [UInt8]
    {
        return try read(mode: mode, while: predicate, body: [UInt8].init)
    }
}

// MARK: read line

extension StreamReader {
    @usableFromInline
    func consumeLineEnd() throws {
        _ = try? consume(.cr)
        _ = try consume(.lf)
    }

    @inlinable
    public func readLine<T>(body: (UnsafeRawBufferPointer) throws -> T) -> T? {
        do {
            let result: T = try read(
                mode: .strict,
                while: { $0 != .cr && $0 != .lf },
                body: body)

            try consumeLineEnd()
            return result
        } catch {
            return nil
        }
    }

    @inlinable
    public func readLine() throws -> String? {
        return try readLine(as: UTF8.self)
    }

    @inlinable
    public func readLine<T>(as encoding: T.Type) throws -> String?
        where T: Unicode.Encoding
    {
        return readLine { bytes in
            guard bytes.count > 0 else { return "" }
            let codeUnits = bytes.bindMemory(to: T.CodeUnit.self)
            return String(decoding: codeUnits, as: encoding)
        }
    }
}
