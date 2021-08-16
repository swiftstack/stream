# Stream

The package does a few things:
1. Abstracts reading&writing from&to file|socket|anything (`buffer` + `size`)
2. Implements [BufferedStream](https://github.com/swiftstack/stream/blob/master/Sources/Stream/Library/BufferedInputStream.swift)
with various `reallocate` options
3. Implements a lot of sugar like
[StreamReader](https://github.com/swiftstack/stream/blob/master/Sources/Stream/StreamReader.swift),
[StreamWriter](https://github.com/swiftstack/stream/blob/master/Sources/Stream/StreamWriter.swift)

## Package.swift

```swift
.package(url: "https://github.com/swiftstack/stream.git", .branch("dev"))
```

## Usage

```swift
let socket = client.accept()
let network = NetworkStream(socket: socket)
let stream = BufferedStream(baseStream: network)

let bytes = try stream.read(count: 10)

let result = try stream.read(count: 10) { rawBufferPointer in
    return rawBufferPointer.count
}
```

## See also

[NetworkStream](https://github.com/swiftstack/aio/blob/master/Sources/Network/NetworkStream/NetworkStream.swift)<br>
[File+Stream](https://github.com/swiftstack/aio/blob/master/Sources/File/File%2BStream.swift)<br>
