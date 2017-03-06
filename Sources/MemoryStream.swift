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
        self.storage = UnsafeMutableRawBufferPointer(
            start: UnsafeMutableRawPointer.allocate(
                bytes: count,
                alignedTo: MemoryLayout<UInt>.alignment),
            count: count)
    }

    /// Non-resizable stream
    public init(capacity: Int) {
        self.expandable = false
        self.storage = UnsafeMutableRawBufferPointer(
            start: UnsafeMutableRawPointer.allocate(
                bytes: capacity,
                alignedTo: MemoryLayout<UInt>.alignment),
            count: capacity)
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
        guard remain >= end else {
            throw StreamError.insufficientData
        }
        position += end
        return UnsafeRawBufferPointer(storage[position-end..<position])
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
        let buffer = try consumeBuffer(count: bytes.count)
        buffer.copyBytes(from: bytes)
        return bytes.count
    }

    fileprivate func reallocate(count: Int) {
        let storage = UnsafeMutableRawBufferPointer(
            start: UnsafeMutableRawPointer.allocate(bytes: count, alignedTo: 8),
            count: count)

        storage.copyBytes(from: self.storage)
        self.storage.deallocate()
        self.storage = storage
    }

    fileprivate func consumeBuffer(count: Int) throws -> UnsafeMutableRawBufferPointer {
        let endIndex = position + count
        if _slowPath(endIndex > storage.count) {
            guard expandable else {
                throw StreamError.notEnoughSpace
            }
            var size = 256
            while endIndex > size {
                size *= 2
            }
            reallocate(count: size)
        }

        let buffer = storage[position..<endIndex]

        position = endIndex
        if position > self.endIndex {
            self.endIndex = position
        }

        return buffer
    }
}

extension MemoryStream {
    @_specialize(Int)
    @_specialize(Int8)
    @_specialize(Int16)
    @_specialize(Int32)
    @_specialize(Int64)
    @_specialize(UInt)
    @_specialize(UInt8)
    @_specialize(UInt16)
    @_specialize(UInt32)
    @_specialize(UInt64)
    public func write<T: Integer>(_ value: T) throws {
        let buffer = try consumeBuffer(count: MemoryLayout<T>.size)
        buffer.baseAddress!.assumingMemoryBound(to: T.self).pointee = value
    }

    @_specialize(Int)
    @_specialize(Int8)
    @_specialize(Int16)
    @_specialize(Int32)
    @_specialize(Int64)
    @_specialize(UInt)
    @_specialize(UInt8)
    @_specialize(UInt16)
    @_specialize(UInt32)
    @_specialize(UInt64)
    public func read<T: Integer>() throws -> T {
        let buffer = try read(upTo: MemoryLayout<T>.size)
        return buffer.baseAddress!.assumingMemoryBound(to: T.self).pointee
    }
}
