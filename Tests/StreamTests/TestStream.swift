import Stream

class TestStream: Stream {
    var storage = [UInt8]()

    func read(to buffer: UnsafeMutableRawPointer, byteCount: Int) throws -> Int {
        let count = min(storage.count, byteCount)
        buffer.copyMemory(from: storage, byteCount: count)
        storage.removeFirst(count)
        return count
    }

    func write(_ bytes: UnsafeRawPointer, byteCount: Int) throws -> Int {
        let buffer = UnsafeRawBufferPointer(start: bytes, count: byteCount)
        storage.append(contentsOf: buffer)
        return byteCount
    }
}
