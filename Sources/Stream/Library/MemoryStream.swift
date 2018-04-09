extension MemoryStream {
    public enum Error: Swift.Error {
        case notEnoughSpace
        case insufficientData
        case invalidSeekOffset
    }
}

public final class MemoryStream: Stream, Seekable {
    var storage: UnsafeMutableRawPointer
    var allocated: Int

    let expandable: Bool

    public private(set) var position = 0
    public private(set) var endIndex = 0

    public var count: Int {
        return endIndex
    }

    public var remain: Int {
        return endIndex - position
    }

    public var capacity: Int {
        return allocated
    }

    public var isEOF: Bool {
        return position == endIndex
    }

    /// Valid until next reallocate
    public var buffer: UnsafeRawBufferPointer {
        return UnsafeRawBufferPointer(start: storage, count: allocated)
    }

    /// Expandable stream with reserved capacity
    public init(reservingCapacity capacity: Int = 0) {
        self.expandable = true
        self.storage = UnsafeMutableRawPointer.allocate(
            byteCount: capacity,
            alignment: MemoryLayout<UInt>.alignment)
        self.allocated = capacity
    }

    /// Non-resizable stream
    public init(capacity: Int) {
        self.expandable = false
        self.storage = UnsafeMutableRawPointer.allocate(
            byteCount: capacity,
            alignment: MemoryLayout<UInt>.alignment)
        self.allocated = capacity
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
        default: throw Error.invalidSeekOffset
        }
    }

    public func read(_ maxLength: Int) -> UnsafeRawBufferPointer {
        return try! read(upTo: Swift.min(remain, maxLength))
    }

    public func read(upTo count: Int) throws -> UnsafeRawBufferPointer {
        guard allocated > 0 else {
            return UnsafeRawBufferPointer(start: nil, count: 0)
        }
        guard remain >= count else {
            throw Error.insufficientData
        }
        let start = storage.advanced(by: position)
        position += count
        return UnsafeRawBufferPointer(start: start, count: count)
    }

    public func read(
        to buffer: UnsafeMutableRawPointer,
        byteCount: Int) throws -> Int
    {
        let bytes = read(byteCount)
        guard bytes.count > 0 else {
            return 0
        }
        buffer.copyMemory(from: bytes.baseAddress!, byteCount: bytes.count)
        return bytes.count
    }

    public func write(
        from buffer: UnsafeRawPointer,
        byteCount: Int) throws -> Int
    {
        guard byteCount > 0 else {
            return 0
        }
        let endIndex = position + byteCount
        try ensure(capacity: endIndex)

        storage.advanced(by: position)
            .copyMemory(from: buffer, byteCount: byteCount)

        position = endIndex
        if position > self.endIndex {
            self.endIndex = position
        }

        return byteCount
    }

    fileprivate func reallocate(byteCount: Int) {
        let storage = UnsafeMutableRawPointer.allocate(
            byteCount: byteCount,
            alignment: MemoryLayout<UInt>.alignment)
        storage.copyMemory(from: self.storage, byteCount: allocated)
        self.storage.deallocate()
        self.storage = storage
        self.allocated = byteCount
    }

    fileprivate func ensure(capacity count: Int) throws {
        if _slowPath(count > allocated) {
            guard expandable else {
                throw Error.notEnoughSpace
            }
            var size = 256
            while count > size {
                size <<= 1
            }
            reallocate(byteCount: size)
        }
    }
}

extension MemoryStream {
    public func write<T: FixedWidthInteger>(_ value: T) throws {
        var value = value.bigEndian
        _ = try write(from: UnsafeRawBufferPointer(
            start: &value, count: MemoryLayout<T>.size))
    }

    public func read<T: FixedWidthInteger>(_ type: T.Type) throws -> T {
        let buffer = try read(upTo: MemoryLayout<T>.size)
        let value = buffer.baseAddress!.assumingMemoryBound(to: T.self).pointee
        return value.bigEndian
    }
}
