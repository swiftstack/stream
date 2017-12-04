public class UnsafeRawInputStream: InputStream {
    let pointer: UnsafeRawPointer
    let count: Int

    public private(set) var position: Int

    public init(pointer: UnsafeRawPointer, count: Int) {
        self.pointer = pointer
        self.count = count
        self.position = 0
    }

    public func read(
        to buffer: UnsafeMutableRawBufferPointer
    ) throws -> Int {
        let count = min(self.count - position, buffer.count)
        let source = UnsafeRawBufferPointer(
            start: pointer.advanced(by: position), count: count)
        buffer.copyBytes(from: source)
        position += count
        return count
    }
}

public class UnsafeRawOutputStream: OutputStream {
    let pointer: UnsafeMutableRawPointer
    let count: Int

    public private(set) var position: Int

    public init(pointer: UnsafeMutableRawPointer, count: Int) {
        self.pointer = pointer
        self.count = count
        self.position = 0
    }

    public func write(_ bytes: UnsafeRawBufferPointer) throws -> Int {
        let count = min(self.count - position, bytes.count)
        guard count > 0 else {
            return 0
        }
        pointer.copyBytes(from: bytes.baseAddress!, count: count)
        position += count
        return count
    }
}
