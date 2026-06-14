import ASCII

extension MemoryStream: StreamReader {
    @usableFromInline
    func ensure(count: Int) throws {
        guard remain >= count else {
            throw StreamError.insufficientData
        }
    }

    @usableFromInline
    func advance(by count: Int) {
        position += count
    }

    public func peek() throws -> UInt8 {
        try ensure(count: 1)
        return buffer[position]
    }

    public func peek<T>(
        count: Int,
        body: (UnsafeRawBufferPointer) throws -> T
    ) throws -> T {
        try ensure(count: count)
        return try body(.init(rebasing: buffer[position..<position+count]))
    }

    public func read(_ type: UInt8.Type) throws -> UInt8 {
        try ensure(count: 1)
        advance(by: 1)
        return buffer[position-1]
    }

    public func read<T: FixedWidthInteger>(_ type: T.Type) throws -> T {
        let count = MemoryLayout<T>.size
        try ensure(count: count)
        var result: T = 0
        withUnsafeMutableBytes(of: &result) { bytes in
            bytes.copyMemory(
                from: .init(
                    rebasing: self.buffer[position..<position+count]
                )
            )
        }
        advance(by: count)
        return result.bigEndian
    }

    public func read<T>(
        count: Int,
        body: (UnsafeRawBufferPointer) throws -> T
    ) throws -> T {
        try ensure(count: count)
        let slice = buffer[position..<position+count]
        advance(by: count)
        return try body(.init(rebasing: slice))
    }

    public func read<T>(
        mode: PredicateMode,
        while predicate: (UInt8) -> Bool,
        body: (UnsafeRawBufferPointer) throws -> T
    ) throws -> T {
        var read = 0
        while true {
            if read == remain {
                if mode == .untilEnd { break }
                throw StreamError.insufficientData
            }
            if !predicate(buffer[position+read]) {
                break
            }
            read += 1
        }
        let slice = buffer[position..<(position+read)]
        advance(by: read)
        return try body(.init(rebasing: slice))
    }

    @inline(always)
    public func consume(count: Int) throws {
        try ensure(count: count)
        advance(by: count)
    }

    public func consume(_ byte: UInt8) throws -> Bool {
        try ensure(count: 1)
        guard buffer[position] == byte else {
            return false
        }
        advance(by: 1)
        return true
    }

    public func consume(
        mode: PredicateMode,
        while predicate: (UInt8) -> Bool
    ) throws {
        while true {
            if position == capacity {
                if mode == .untilEnd { break }
                throw StreamError.insufficientData
            }
            if !predicate(buffer[position]) {
                break
            }
            advance(by: 1)
        }
    }

    public func cache(count: Int) throws -> Bool {
        do {
            try ensure(count: count)
            return true
        } catch {
            return false
        }
    }
}

// Sync StreamReader extension overrides

extension MemoryStream {
    @inline(__always)
    public func read<T>(
        until byte: UInt8,
        body: (UnsafeRawBufferPointer) throws -> T
    ) throws -> T {
        return try read(
            mode: .strict,
            while: { $0 != byte },
            body: body)
    }

    @inline(__always)
    public func readUntilEnd<T>(
        body: (UnsafeRawBufferPointer) throws -> T
    ) throws -> T {
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
    public func consume(set: Set<UInt8>) throws {
        try consume(while: set.contains)
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

extension MemoryStream {
    @inline(__always)
    public func read<T>(
        while predicate: (UInt8) -> Bool,
        body: (UnsafeRawBufferPointer) throws -> T
    ) throws -> T {
        return try read(mode: .untilEnd, while: predicate, body: body)
    }

    @inline(__always)
    public func consume(while predicate: (UInt8) -> Bool) throws {
        try consume(mode: .untilEnd, while: predicate)
    }
}

// MARK: [UInt8]

extension MemoryStream {
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
        while predicate: (UInt8) -> Bool
    ) throws -> [UInt8] {
        return try read(mode: mode, while: predicate, body: [UInt8].init)
    }
}

// MARK: read line

extension MemoryStream {
    @usableFromInline
    func consumeLineEnd() throws {
        _ = try? consume(.cr)
        _ = try consume(.lf)
    }

    @inlinable
    public func readLine<T>(
        body: (UnsafeRawBufferPointer) throws -> T
    ) -> T? {
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
