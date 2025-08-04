import Stream

class TestStream: Stream {
    var bytes = [UInt8]()

    func read(
        to buffer: UnsafeMutableRawPointer,
        byteCount: Int
    ) -> Int {
        let count = min(bytes.count, byteCount)
        buffer.copyMemory(from: bytes, byteCount: count)
        bytes.removeFirst(count)
        return count
    }

    func write(
        from buffer: UnsafeRawPointer,
        byteCount: Int
    ) -> Int {
        let buffer = UnsafeRawBufferPointer(start: buffer, count: byteCount)
        bytes.append(contentsOf: buffer)
        return byteCount
    }
}
