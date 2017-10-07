import Stream

class TestStream: Stream {
    var storage = [UInt8]()

    func read(to buffer: UnsafeMutableRawBufferPointer) throws -> Int {
        let count = min(storage.count, buffer.count)
        buffer.copyBytes(from: storage[..<count])
        storage = [UInt8](storage[count...])
        return count
    }

    func write(_ bytes: UnsafeRawBufferPointer) throws -> Int {
        storage.append(contentsOf: bytes)
        return bytes.count
    }
}
