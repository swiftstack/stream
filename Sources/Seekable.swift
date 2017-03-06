public enum SeekOrigin {
    case begin, current, end
}

protocol Seekable {
    func seek(to offset: Int, from origin: SeekOrigin) throws
}
