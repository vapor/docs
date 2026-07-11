# 파일(Files)

Vapor는 라우트 핸들러 내에서 파일을 비동기적으로 읽고 쓸 수 있는 간단한 API를 제공합니다. 이 API는 NIO의 [`NonBlockingFileIO`](https://swiftpackageindex.com/apple/swift-nio/main/documentation/nioposix/nonblockingfileio) 타입 위에 구축되어 있습니다.

## 읽기(Read)

파일을 읽기 위한 주요 메서드는 디스크에서 읽어들이는 동안 청크 단위로 콜백 핸들러에 전달합니다. 읽을 파일은 경로로 지정합니다. 상대 경로를 사용하면 프로세스의 현재 작업 디렉터리에서 찾습니다.

```swift
// Asynchronously reads a file from disk.
let readComplete: EventLoopFuture<Void> = req.fileio.readFile(at: "/path/to/file") { chunk in
    print(chunk) // ByteBuffer
}

// Or

try await req.fileio.readFile(at: "/path/to/file") { chunk in
    print(chunk) // ByteBuffer
}
// Read is complete
```

`EventLoopFuture`를 사용한다면, 반환된 future는 읽기가 완료되거나 에러가 발생했을 때 신호를 보냅니다. `async`/`await`를 사용한다면 `await`가 반환된 시점에 읽기가 완료된 것입니다. 에러가 발생한 경우에는 에러를 던집니다.

### 스트림(Stream)

`streamFile` 메서드는 스트리밍되는 파일을 `Response`로 변환합니다. 이 메서드는 `ETag`, `Content-Type`과 같은 적절한 헤더를 자동으로 설정합니다.

```swift
// Asynchronously streams file as HTTP response.
req.fileio.streamFile(at: "/path/to/file").map { res in
    print(res) // Response
}

// Or

let res = req.fileio.streamFile(at: "/path/to/file")
print(res)

```

결과는 여러분의 라우트 핸들러에서 바로 반환할 수 있습니다.

### 수집(Collect)

`collectFile` 메서드는 지정한 파일을 버퍼로 읽어들입니다.

```swift
// Reads the file into a buffer.
req.fileio.collectFile(at: "/path/to/file").map { buffer in 
    print(buffer) // ByteBuffer
}

// or

let buffer = req.fileio.collectFile(at: "/path/to/file")
print(buffer)
```

!!! warning
    이 메서드는 파일 전체가 한 번에 메모리에 올라가야 합니다. 메모리 사용량을 제한하려면 청크 단위 읽기나 스트리밍 읽기를 사용하세요.

## 쓰기(Write)

`writeFile` 메서드는 버퍼를 파일에 쓰는 것을 지원합니다.

```swift
// Writes buffer to file.
req.fileio.writeFile(ByteBuffer(string: "Hello, world"), at: "/path/to/file")
```

반환된 future는 쓰기가 완료되거나 에러가 발생했을 때 신호를 보냅니다.

## 미들웨어(Middleware)

프로젝트의 _Public_ 폴더에 있는 파일을 자동으로 제공하는 것에 대한 더 많은 정보는 [미들웨어 &rarr; FileMiddleware](middleware.md#file-middleware)를 참고하세요.

## 심화(Advanced)

Vapor의 API가 지원하지 않는 경우에는 NIO의 `NonBlockingFileIO` 타입을 직접 사용할 수 있습니다.

```swift
// Main thread.
let fileHandle = try await app.fileio.openFile(
    path: "/path/to/file", 
    eventLoop: app.eventLoopGroup.next()
).get()
print(fileHandle)

// In a route handler.
let fileHandle = try await req.application.fileio.openFile(
    path: "/path/to/file", 
    eventLoop: req.eventLoop)
print(fileHandle)
```

더 많은 정보는 SwiftNIO의 [API 참조 문서](https://swiftpackageindex.com/apple/swift-nio/main/documentation/nioposix/nonblockingfileio)를 방문해 보세요.
