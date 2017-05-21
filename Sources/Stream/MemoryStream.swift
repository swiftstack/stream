public final class MemoryStream: Stream, Seekable {
    var storage: UnsafeMutableRawBufferPointer
    let expandable: Bool

    public private(set) var position = 0
    public private(set) var endIndex = 0

    public var count: Int {
        return endIndex
    }

    public var remain: Int {
        return endIndex - position
    }

    public var allocated: Int {
        return storage.count
    }

    public var isEOF: Bool {
        return position == endIndex
    }

    /// Valid until next reallocate
    public var buffer: UnsafeRawBufferPointer {
        return UnsafeRawBufferPointer(storage)
    }

    /// Expandable stream
    public init() {
        self.expandable = true
        self.storage = UnsafeMutableRawBufferPointer(start: nil, count: 0)
    }

    /// Expandable stream with reserved capacity
    public init(reservingCapacity count: Int) {
        self.expandable = true
        self.storage = UnsafeMutableRawBufferPointer.allocate(count: count)
    }

    /// Non-resizable stream
    public init(capacity: Int) {
        self.expandable = false
        self.storage = UnsafeMutableRawBufferPointer.allocate(count: capacity)
    }

    deinit {
        storage.deallocate()
    }

    public func seek(to offset: Int, from origin: SeekOrigin) throws {
        var position: Int

        switch origin {
        case .begin: position = offset
        case .current: position = self.position + offset
        case .end: position = self.endIndex + offset
        }

        switch position {
        case 0...endIndex: self.position = position
        default: throw StreamError.invalidSeekOffset
        }
    }

    public func read(_ maxLength: Int) -> UnsafeRawBufferPointer {
        return try! read(upTo: Swift.min(remain, maxLength))
    }

    public func read(upTo end: Int) throws -> UnsafeRawBufferPointer {
        guard storage.baseAddress != nil else {
            return UnsafeRawBufferPointer(start: nil, count: 0)
        }
        guard remain >= end else {
            throw StreamError.insufficientData
        }
        position += end
        return UnsafeRawBufferPointer(
            rebasing: storage[position-end..<position])
    }

    public func read(to buffer: UnsafeMutableRawBufferPointer) throws -> Int {
        let bytes = read(buffer.count)
        guard bytes.count > 0 else {
            return 0
        }
        buffer.copyBytes(from: bytes)
        return bytes.count
    }

    public func write(_ bytes: UnsafeRawBufferPointer) throws -> Int {
        guard bytes.count > 0 else {
            return 0
        }
        let endIndex = position + bytes.count
        try ensure(capacity: endIndex)

        UnsafeMutableRawBufferPointer(rebasing: storage[position..<endIndex])
            .copyBytes(from: bytes)

        position = endIndex
        if position > self.endIndex {
            self.endIndex = position
        }

        return bytes.count
    }

    fileprivate func reallocate(count: Int) {
        let storage = UnsafeMutableRawBufferPointer.allocate(count: count)
        storage.copyBytes(from: self.storage)
        self.storage.deallocate()
        self.storage = storage
    }

    fileprivate func ensure(capacity count: Int) throws {
        if _slowPath(count > storage.count) {
            guard expandable else {
                throw StreamError.notEnoughSpace
            }
            var size = 256
            while count > size {
                size <<= 1
            }
            reallocate(count: size)
        }
    }
}

extension MemoryStream {
    public func write<T: Numeric>(_ value: T) throws {
        var value = value
        _ = try withUnsafeBytes(of: &value) { buffer in
            try write(buffer)
        }
    }

    public func read<T: Numeric>(_ type: T.Type) throws -> T {
        let buffer = try read(upTo: MemoryLayout<T>.size)
        return buffer.baseAddress!.assumingMemoryBound(to: T.self).pointee
    }
}
