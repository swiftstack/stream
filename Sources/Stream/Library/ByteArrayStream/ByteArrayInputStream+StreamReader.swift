extension ByteArrayInputStream: StreamReader {
    public var buffered: Int {
        return bytes.count - position
    }

    @inline(__always)
    func ensure(count: Int) throws(StreamError) {
        guard buffered >= count else {
            throw StreamError.insufficientData
        }
    }

    @inline(__always)
    func advance(by count: Int) {
        position += count
    }

    public func peek() throws(StreamError) -> UInt8 {
        try ensure(count: 1)
        return bytes[position]
    }

    public func peek<T>(
        count: Int,
        body: (UnsafeRawBufferPointer) throws(StreamError) -> T
    ) throws(StreamError) -> T {
        try ensure(count: count)
        // FIXME: Thrown expression type 'any Error' cannot be converted to error type 'StreamError'
        do {
            return try bytes[position..<position+count].withUnsafeBytes(body)
        } catch {
            throw error as! StreamError
        }
    }

    public func read(_ type: UInt8.Type) throws(StreamError) -> UInt8 {
        try ensure(count: 1)
        advance(by: 1)
        return bytes[position-1]
    }

    public func read<T: FixedWidthInteger>(_ type: T.Type) throws(StreamError) -> T {
        let count = MemoryLayout<T>.size
        try ensure(count: count)
        var result: T = 0
        bytes[position..<position+count].withUnsafeBytes { bytes in
            withUnsafeMutableBytes(of: &result) { buffer in
                buffer.copyMemory(from: bytes)
            }
        }
        advance(by: count)
        return result.bigEndian
    }

    public func read<T>(
        count: Int,
        body: (UnsafeRawBufferPointer) throws(StreamError) -> T
    ) throws(StreamError) -> T {
        try ensure(count: count)
        let slice = bytes[position..<position+count]
        advance(by: count)
        // FIXME: Thrown expression type 'any Error' cannot be converted to error type 'StreamError'
        do {
            return try slice.withUnsafeBytes(body)
        } catch {
            throw error as! StreamError
        }
    }

    public func read<T>(
        mode: PredicateMode,
        while predicate: (UInt8) -> Bool,
        body: (UnsafeRawBufferPointer) throws(StreamError) -> T
    ) throws(StreamError) -> T {
        var read = 0
        while true {
            if read == buffered {
                if mode == .untilEnd { break }
                throw StreamError.insufficientData
            }
            if !predicate(bytes[position+read]) {
                break
            }
            read += 1
        }
        let slice = bytes[position..<(position+read)]
        advance(by: read)
        // FIXME: Thrown expression type 'any Error' cannot be converted to error type 'StreamError'
        do {
            return try slice.withUnsafeBytes(body)
        } catch {
            throw error as! StreamError
        }
    }

    public func consume(count: Int) throws(StreamError) {
        try ensure(count: count)
        advance(by: count)
    }

    public func consume(_ byte: UInt8) throws(StreamError) -> Bool {
        try ensure(count: 1)
        guard bytes[position] == byte else {
            return false
        }
        advance(by: 1)
        return true
    }

    public func consume(
        mode: PredicateMode,
        while predicate: (UInt8) -> Bool
    ) throws(StreamError) {
        while true {
            if position == bytes.count {
                if mode == .untilEnd { break }
                throw StreamError.insufficientData
            }
            if !predicate(bytes[position]) {
                break
            }
            advance(by: 1)
        }
    }

    public func cache(count: Int) throws(StreamError) -> Bool {
        do {
            try ensure(count: count)
            return true
        } catch {
            return false
        }
    }
}

extension ByteArrayInputStream {
    @inline(__always)
    public func read<T>(
        until byte: UInt8,
        body: (UnsafeRawBufferPointer) throws(StreamError) -> T
    ) throws(StreamError) -> T {
        return try read(
            mode: .strict,
            while: { $0 != byte },
            body: body)
    }

    @inline(__always)
    public func readUntilEnd<T>(
        body: (UnsafeRawBufferPointer) throws(StreamError) -> T
    ) throws(StreamError) -> T {
        return try read(
            mode: .untilEnd,
            while: { _ in true },
            body: body)
    }

    public func consume(until byte: UInt8) throws(StreamError) {
        try consume(mode: .strict, while: { $0 != byte })
    }

    @inlinable
    public func consume<T>(sequence bytes: T) throws(StreamError) -> Bool
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
    public func consume(set: Set<UInt8>) throws(StreamError) {
        try consume(while: set.contains)
    }

    @inlinable
    public func next<T: Collection>(is elements: T) throws(StreamError) -> Bool
    where T.Element == UInt8
    {
        return try peek(count: elements.count) { bytes in
            return bytes.elementsEqual(elements)
        }
    }
}

// MARK: untilEnd = true by default

extension ByteArrayInputStream {
    @inline(__always)
    public func read<T>(
        while predicate: (UInt8) -> Bool,
        body: (UnsafeRawBufferPointer) throws(StreamError) -> T
    ) throws(StreamError) -> T {
        return try read(mode: .untilEnd, while: predicate, body: body)
    }

    @inline(__always)
    public func consume(while predicate: (UInt8) -> Bool) throws(StreamError) {
        try consume(mode: .untilEnd, while: predicate)
    }
}

// MARK: [UInt8]

extension ByteArrayInputStream {
    public func read(until byte: UInt8) throws(StreamError) -> [UInt8] {
        return try read(until: byte, body: [UInt8].init)
    }

    @inlinable
    public func read(count: Int) throws(StreamError) -> [UInt8] {
        return try read(count: count, body: [UInt8].init)
    }

    @inlinable
    public func read(
        mode: PredicateMode = .untilEnd,
        while predicate: (UInt8) -> Bool
    ) throws(StreamError) -> [UInt8] {
        return try read(mode: mode, while: predicate, body: [UInt8].init)
    }
}

// MARK: read line

extension ByteArrayInputStream {
    @usableFromInline
    func consumeLineEnd() throws(StreamError) {
        _ = try? consume(.cr)
        _ = try consume(.lf)
    }

    @inlinable
    public func readLine<T>(
        body: (UnsafeRawBufferPointer) throws(StreamError) -> T
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
    public func readLine() throws(StreamError) -> String? {
        return try readLine(as: UTF8.self)
    }

    @inlinable
    public func readLine<T>(as encoding: T.Type) throws(StreamError) -> String?
    where T: Unicode.Encoding
    {
        return readLine { bytes in
            guard bytes.count > 0 else { return "" }
            let codeUnits = bytes.bindMemory(to: T.CodeUnit.self)
            return String(decoding: codeUnits, as: encoding)
        }
    }
}
