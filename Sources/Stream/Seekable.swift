public enum SeekOrigin {
    case begin, current, end
}

public protocol Seekable {
    func seek(to offset: Int, from origin: SeekOrigin) throws
}
