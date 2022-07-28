# 文件

Vapor 提供了一个简单的 API，用于在路由内部处理异步读取和写入文件。API 是在 NIO 的  [`NonBlockingFileIO`](https://apple.github.io/swift-nio/docs/current/NIOPosix/Structs/NonBlockingFileIO.html) 类型上构建的。

## 读取

读取文件的主要方法在从磁盘读取块时将块传递给回调处理程序。要读取的文件由其路径指定。相对路径将在进程的当前工作目录中查找。

```swift
// 异步地从磁盘读取文件。
let readComplete: EventLoopFuture<Void> = req.fileio.readFile(at: "/path/to/file") { chunk in
    print(chunk) // ByteBuffer
}

// 或者

try await req.fileio.readFile(at: "/path/to/file") { chunk in
    print(chunk) // ByteBuffer
}
// 读取完成
```

如果使用 `EventLoopFutures`，则读取完成或发生错误时，返回的 future 将发出信号。如果使用 `async`/`await` 则一旦 `await` 返回，读取就完成了。如果发生错误，它会抛出一个错误。

### 流

`streamFile` 方法将文件流转换为 `Response`。 此方法将自动设置适当的响应头，例如 `ETag` 和 `Content-Type`。

```swift
// 异步流文件作为HTTP响应。
req.fileio.streamFile(at: "/path/to/file").map { res in
    print(res) // 响应
}

// 或者

let res = req.fileio.streamFile(at: "/path/to/file")
print(res)

```

路由处理程序可以直接将结果返回。

### Collect 

`collectFile` 方法将指定的文件读入缓冲区。

```swift
// 去读文件到缓冲区
req.fileio.collectFile(at: "/path/to/file").map { buffer in 
    print(buffer) // ByteBuffer
}

// 或者

let buffer = req.fileio.collectFile(at: "/path/to/file")
print(buffer)
```

!!! 警告
    此方法要求整个文件一次性加载到内存中。使用分块或流式读取来限制内存使用。

## 写入

`writeFile` 方法支持将缓冲区数据写入文件。

```swift
// 将缓冲区数据写入文件
req.fileio.writeFile(ByteBuffer(string: "Hello, world"), at: "/path/to/file")
```

当写入完成或发生错误时，返回的 future 将发出信号。

## 中间件

了解关于从项目的 _Public_ 文件夹自动提供文件的更多信息，请参阅 [中间件 → 文件中间件](middleware.zh.md#file-middleware)。

## 进阶

对于 Vapor API 不支持的情况，你可以直接使用 NIO 的 `NonBlockingFileIO` 类型。

```swift
// 主线程。
let fileHandle = try await app.fileio.openFile(
    path: "/path/to/file", 
    eventLoop: app.eventLoopGroup.next()
).get()
print(fileHandle)

// 在路由处理程序中。
let fileHandle = try await req.application.fileio.openFile(
    path: "/path/to/file", 
    eventLoop: req.eventLoop)
print(fileHandle)
```

了解更多信息，请参阅 SwiftNIO 的 [API 文档](https://apple.github.io/swift-nio/docs/current/NIOPosix/Structs/NonBlockingFileIO.html)。
