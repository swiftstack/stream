public class MemoryStream: Stream {
    var capacity: Int? = nil
    var storage: UnsafeMutableRawPointer
    private(set) var allocated = 0
    private(set) var offset = 0
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
            offset = 0
        } else {
            offset += count
        }

        return count
    }

    public func write(from buffer: UnsafeRawPointer, count: Int) throws -> Int {
        guard count > 0 else {
            return 0
        }

        let available = try ensure(count: count)
        storage.advanced(by: writePosition)
            .copyBytes(from: buffer, count: available)
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
                throw StreamError.noSpaceAvailable
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
