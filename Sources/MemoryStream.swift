public class MemoryStream: Stream {
    var capacity: Int? = nil
    var storage: UnsafeMutableRawPointer
    private(set) var allocated = 0
    fileprivate(set) var offset = 0
    var writePosition: Int {
        return offset + count
    }

    public fileprivate(set) var count = 0

    /// Expandable stream
    public init(reservingCapacity count: Int = 8) {
        self.allocated = count
        self.storage = UnsafeMutableRawPointer.allocate(bytes: count, alignedTo: 0)
    }

    /// Non-resizable stream
    public init(capacity: Int) {
        self.capacity = capacity
        self.allocated = capacity
        self.storage = UnsafeMutableRawPointer.allocate(bytes: capacity, alignedTo: 0)
    }

    deinit {
        storage.deallocate(bytes: allocated, alignedTo: 0)
    }

    public func read(to buffer: UnsafeMutableRawPointer, count: Int) throws -> Int {
        let count = min(self.count, count)
        guard count > 0 else {
            return 0
        }

        buffer.copyBytes(from: storage.advanced(by: offset), count: count)

        self.count -= count
        if self.count == 0 {
            self.offset = 0
        } else {
            self.offset += count
        }

        return count
    }

    public func write(_ bytes: UnsafeRawPointer, count: Int) throws -> Int {
        guard count > 0 else {
            return 0
        }

        let available = try ensure(count: count)
        storage.advanced(by: writePosition)
            .copyBytes(from: bytes, count: available)
        self.count += available
        return available
    }

    fileprivate func shift() {
        storage.copyBytes(from: storage.advanced(by: offset), count: count)
        offset = 0
    }

    fileprivate func reallocate(count: Int) {
        let storage = UnsafeMutableRawPointer.allocate(bytes: count, alignedTo: 0)
        if self.count > 0 {
            storage.copyBytes(from: self.storage.advanced(by: offset), count: self.count)
            offset = 0
        }
        self.storage.deallocate(bytes: self.allocated, alignedTo: 0)
        self.storage = storage
        self.allocated = count
    }

    fileprivate func ensure(count: Int) throws -> Int {
        var available = count

        if let capacity = capacity {
            guard self.count < capacity else {
                throw StreamError.full
            }
            available = min(capacity - self.count, count)
            if writePosition + count > capacity {
                shift()
            }
        } else if writePosition + count > allocated {
            if self.count + count <= allocated / 2 {
                shift()
            } else {
                reallocate(count: (self.count + count) * 2)
            }
        }

        return available
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
        // ensure we have enough space
        let size = MemoryLayout<T>.size
        let available = try ensure(count: size)
        guard available == size else {
            throw StreamError.notEnoughSpace
        }
        // for the value
        storage.advanced(by: writePosition)
            .assumingMemoryBound(to: T.self)
            .pointee = value
        count += size
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
        guard count > 0 else {
            throw StreamError.eof
        }
        // ensure we have enough data
        let size = MemoryLayout<T>.size
        guard count >= size else {
            throw StreamError.insufficientData
        }
        // for the value
        let value = storage.advanced(by: offset)
            .assumingMemoryBound(to: T.self)
            .pointee

        count -= size
        if count == 0 {
            offset = 0
        } else {
            offset += size
        }

        return value
    }
}
