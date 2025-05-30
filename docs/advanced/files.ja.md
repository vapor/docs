# ファイル {#files}

Vaporは、ルートハンドラ内でファイルを非同期に読み書きするためのシンプルなAPIを提供しています。このAPIは、NIOの[`NonBlockingFileIO`](https://swiftpackageindex.com/apple/swift-nio/main/documentation/nioposix/nonblockingfileio)型の上に構築されています。

## 読み取り {#read}

ファイルを読み取るための主要なメソッドは、ディスクから読み取られたチャンクをコールバックハンドラに配信します。読み取るファイルはパスで指定します。相対パスは、プロセスの現在の作業ディレクトリを参照します。

```swift
// ディスクからファイルを非同期に読み取ります。
let readComplete: EventLoopFuture<Void> = req.fileio.readFile(at: "/path/to/file") { chunk in
    print(chunk) // ByteBuffer
}

// または

try await req.fileio.readFile(at: "/path/to/file") { chunk in
    print(chunk) // ByteBuffer
}
// 読み取り完了
```

`EventLoopFuture`を使用している場合、返されたfutureは読み取りが完了したか、エラーが発生したときにシグナルを送ります。`async`/`await`を使用している場合、`await`が返ると読み取りが完了しています。エラーが発生した場合は、エラーをスローします。

### ストリーム {#stream}

`streamFile`メソッドは、ストリーミングファイルを`Response`に変換します。このメソッドは、`ETag`や`Content-Type`などの適切なヘッダーを自動的に設定します。

```swift
// ファイルを非同期にHTTPレスポンスとしてストリームします。
req.fileio.streamFile(at: "/path/to/file").map { res in
    print(res) // Response
}

// または

let res = req.fileio.streamFile(at: "/path/to/file")
print(res)

```

結果は、ルートハンドラから直接返すことができます。

### 収集 {#collect}

`collectFile`メソッドは、指定されたファイルをバッファに読み込みます。

```swift
// ファイルをバッファに読み込みます。
req.fileio.collectFile(at: "/path/to/file").map { buffer in 
    print(buffer) // ByteBuffer
}

// または

let buffer = req.fileio.collectFile(at: "/path/to/file")
print(buffer)
```

!!! warning
    このメソッドは、ファイル全体を一度にメモリに読み込む必要があります。メモリ使用量を制限するには、チャンクまたはストリーミング読み取りを使用してください。

## 書き込み {#write}

`writeFile`メソッドは、バッファをファイルに書き込むことをサポートしています。

```swift
// バッファをファイルに書き込みます。
req.fileio.writeFile(ByteBuffer(string: "Hello, world"), at: "/path/to/file")
```

返されたfutureは、書き込みが完了したか、エラーが発生したときにシグナルを送ります。

## ミドルウェア {#middleware}

プロジェクトの_Public_フォルダから自動的にファイルを提供する方法の詳細については、[ミドルウェア &rarr; FileMiddleware](middleware.md#file-middleware)を参照してください。

## 高度な使い方 {#advanced}

VaporのAPIがサポートしていないケースでは、NIOの`NonBlockingFileIO`型を直接使用できます。

```swift
// メインスレッド。
let fileHandle = try await app.fileio.openFile(
    path: "/path/to/file", 
    eventLoop: app.eventLoopGroup.next()
).get()
print(fileHandle)

// ルートハンドラ内。
let fileHandle = try await req.application.fileio.openFile(
    path: "/path/to/file", 
    eventLoop: req.eventLoop)
print(fileHandle)
```

詳細については、SwiftNIOの[APIリファレンス](https://swiftpackageindex.com/apple/swift-nio/main/documentation/nioposix/nonblockingfileio)をご覧ください。