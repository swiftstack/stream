public final class MemoryStream {
    var buffer: UnsafeMutableRawBufferPointer

    let expandable: Bool

    public internal(set) var position = 0

    public var capacity: Int {
        return buffer.count
    }

    public var remain: Int {
        return buffer.count - position
    }

    public var isEOF: Bool {
        return position == buffer.count
    }

    /// Expandable stream with reserved capacity
    public init(reservingCapacity capacity: Int = 0) {
        self.expandable = true
        self.buffer = UnsafeMutableRawBufferPointer
            .allocate(
                byteCount: capacity,
                alignment: MemoryLayout<UInt>.alignment
            )
    }

    /// Non-resizable stream
    public init(capacity: Int) {
        self.expandable = false
        self.buffer = UnsafeMutableRawBufferPointer
            .allocate(
                byteCount: capacity,
                alignment: MemoryLayout<UInt>.alignment
            )
    }

    deinit {
        buffer.deallocate()
    }

    public func withUnsafeBufferPointer<R>(
        _ body: (UnsafeRawBufferPointer) throws -> R
    ) rethrows -> R {
        try body(.init(rebasing: buffer[..<position]))
    }

    public func withUnsafeBufferPointer<R>(
        _ body: (UnsafeRawBufferPointer) async throws -> R
    ) async rethrows -> R {
        try await body(.init(rebasing: buffer[..<position]))
    }

    public func withUnsafeMutableBufferPointer<R>(
        _ body: (UnsafeMutableRawBufferPointer) throws -> R
    ) rethrows -> R {
        try body(.init(rebasing: buffer[..<position]))
    }

    public func withUnsafeMutableBufferPointer<R>(
        _ body: (UnsafeMutableRawBufferPointer) async throws -> R
    ) async rethrows -> R {
        try await body(.init(rebasing: buffer[..<position]))
    }
}

extension MemoryStream: InputStream {
    public func read(
        to buffer: UnsafeMutableRawPointer,
        byteCount: Int
    ) throws -> Int {
        precondition(byteCount >= 0)
        let byteCount = min(byteCount, remain)
        buffer.copyMemory(
            from: self.buffer.baseAddress!.advanced(by: position),
            byteCount: byteCount
        )
        position += byteCount
        return byteCount
    }
}

extension MemoryStream: OutputStream {
    public func write(
        from buffer: UnsafeRawPointer,
        byteCount: Int
    ) throws -> Int {
        precondition(byteCount >= 0)
        if _slowPath(byteCount > remain && expandable) {
            reallocate(reserving: byteCount)
        }
        let byteCount = min(byteCount, remain)
        self.buffer.baseAddress!.advanced(by: position).copyMemory(
            from: buffer,
            byteCount: byteCount
        )
        position += byteCount
        return byteCount
    }

    func reallocate(reserving byteCount: Int) {
        let byteCount = nextSize(reserving: byteCount)
        let buffer = UnsafeMutableRawBufferPointer
            .allocate(
                byteCount: byteCount,
                alignment: MemoryLayout<UInt>.alignment
            )
        buffer.copyBytes(from: self.buffer)
        self.buffer.deallocate()
        self.buffer = buffer
    }

    fileprivate func nextSize(reserving byteCount: Int) -> Int {
        var size = 256
        while (capacity + byteCount) > size {
            size <<= 1
        }
        return size
    }
}

extension MemoryStream: Seekable {
    public func seek(to offset: Int, from origin: SeekOrigin) throws {
        var position: Int

        switch origin {
        case .begin: position = offset
        case .current: position = self.position + offset
        case .end: position = self.capacity + offset
        }

        switch position {
        case 0...capacity: self.position = position
        default: throw StreamError.invalidSeekOffset
        }
    }
}
