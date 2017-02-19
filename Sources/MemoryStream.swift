public class MemoryStream: Stream {
    var capacity: Int? = nil
    var storage: UnsafeMutablePointer<UInt8>
    var allocated = 0
    var count = 0
    var start = 0
    var end: Int {
        return start + count
    }

    public init() {
        storage = UnsafeMutablePointer<UInt8>.allocate(capacity: 8)
        allocated = 8
    }

    public init(capacity: Int) {
        self.capacity = capacity
        storage = UnsafeMutablePointer<UInt8>.allocate(capacity: capacity)
    }

    public func read(to buffer: UnsafeMutableRawPointer, count: Int) throws -> Int {
        let count = min(self.count, count)
        guard count > 0 else {
            return 0
        }

        buffer.initializeMemory(
            as: UInt8.self,
            from: storage.advanced(by: start),
            count: count)

        self.count -= count
        if self.count == 0 {
            start = 0
        } else {
            start += count
        }

        return count
    }

    fileprivate func shift() {
        storage.moveInitialize(from: storage.advanced(by: start), count: self.count)
        self.start = 0
    }

    fileprivate func reallocate(count: Int) {
        let storage = UnsafeMutablePointer<UInt8>.allocate(capacity: count)
        if self.count > 0 {
            storage.moveInitialize(from: self.storage, count: self.count)
        }
        self.storage.deallocate(capacity: self.allocated)
        self.storage = storage
        self.allocated = count
    }

    public func write(from buffer: UnsafeRawPointer, count: Int) throws -> Int {
        var count = count
        guard count > 0 else {
            return 0
        }

        if let capacity = capacity {
            guard self.count < capacity else {
                throw StreamError.noSpaceAvailable
            }
            count = min(capacity - self.count, count)
            if end + count > capacity {
                shift()
            }
        } else if end + count > allocated {
            if self.count + count <= allocated / 2 {
                shift()
            } else {
                reallocate(count: (self.count + count) * 2)
            }
        }

        storage.advanced(by: start + self.count)
            .initialize(
                from: buffer.assumingMemoryBound(to: UInt8.self),
                count: count)

        self.count += count

        return count
    }
}
