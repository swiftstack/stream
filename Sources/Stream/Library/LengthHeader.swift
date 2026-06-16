public protocol LengthHeader: StreamWritable & StreamReadable {
    init(_ value: Int)
    var value: Int { get }
}
