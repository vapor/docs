# WebSockets

[WebSockets](https://en.wikipedia.org/wiki/WebSocket)は、クライアントとサーバー間の双方向通信を可能にします。リクエストとレスポンスのパターンを持つHTTPとは異なり、WebSocketのピアは任意の数のメッセージを双方向に送信できます。VaporのWebSocket APIを使用すると、メッセージを非同期に処理するクライアントとサーバーの両方を作成できます。

## サーバー {#server}

WebSocketエンドポイントは、Routing APIを使用して既存のVaporアプリケーションに追加できます。`get`や`post`を使用するのと同じように`webSocket`メソッドを使用します。

```swift
app.webSocket("echo") { req, ws in
    // 接続されたWebSocket
    print(ws)
}
```

WebSocketルートは、通常のルートと同様にグループ化し、ミドルウェアで保護できます。

WebSocketハンドラーは、受信HTTPリクエストを受け入れるだけでなく、新しく確立されたWebSocket接続も受け入れます。このWebSocketを使用してメッセージを送受信する方法については、以下を参照してください。

## クライアント {#client}

リモートのWebSocketエンドポイントに接続するには、`WebSocket.connect`を使用します。

```swift
WebSocket.connect(to: "ws://echo.websocket.org", on: eventLoop) { ws in
    // 接続されたWebSocket
    print(ws)
}
```

`connect`メソッドは、接続が確立されたときに完了するfutureを返します。接続されると、新しく接続されたWebSocketで提供されたクロージャが呼び出されます。このWebSocketを使用してメッセージを送受信する方法については、以下を参照してください。

## メッセージ {#messages}

`WebSocket`クラスには、メッセージの送受信やクローズなどのイベントのリスニングのためのメソッドがあります。WebSocketは、テキストとバイナリの2つのプロトコルでデータを送信できます。テキストメッセージはUTF-8文字列として解釈され、バイナリデータはバイト配列として解釈されます。

### 送信 {#sending}

メッセージはWebSocketの`send`メソッドを使用して送信できます。

```swift
ws.send("Hello, world")
```

このメソッドに`String`を渡すと、テキストメッセージが送信されます。`[UInt8]`を渡すことでバイナリメッセージを送信できます。

```swift
ws.send([1, 2, 3])
```

メッセージの送信は非同期です。sendメソッドに`EventLoopPromise`を提供して、メッセージの送信が完了したか失敗したかを通知できます。

```swift
let promise = eventLoop.makePromise(of: Void.self)
ws.send(..., promise: promise)
promise.futureResult.whenComplete { result in
    // 送信に成功または失敗
}
```

`async`/`await`を使用している場合は、`await`を使用して非同期操作の完了を待つことができます。

```swift
try await ws.send(...)
```

### 受信 {#receiving}

受信メッセージは`onText`と`onBinary`コールバックで処理されます。

```swift
ws.onText { ws, text in
    // このWebSocketが受信した文字列
    print(text)
}

ws.onBinary { ws, binary in
    // このWebSocketが受信した[UInt8]
    print(binary)
}
```

参照サイクルを防ぐため、WebSocket自体がこれらのコールバックの最初のパラメータとして提供されます。データを受信した後、WebSocketに対してアクションを実行するには、この参照を使用します。例えば、返信を送信する場合：

```swift
// 受信したメッセージをエコーバック
ws.onText { ws, text in
    ws.send(text)
}
```

## クローズ {#closing}

WebSocketを閉じるには、`close`メソッドを呼び出します。

```swift
ws.close()
```

このメソッドは、WebSocketが閉じられたときに完了するfutureを返します。`send`と同様に、このメソッドにpromiseを渡すこともできます。

```swift
ws.close(promise: nil)
```

または、`async`/`await`を使用している場合は`await`できます：

```swift
try await ws.close()
```

ピアが接続を閉じたときに通知を受けるには、`onClose`を使用します。このfutureは、クライアントまたはサーバーがWebSocketを閉じたときに完了します。

```swift
ws.onClose.whenComplete { result in
    // クローズに成功または失敗
}
```

`closeCode`プロパティは、WebSocketが閉じられたときに設定されます。これを使用して、ピアが接続を閉じた理由を判断できます。

## Ping / Pong {#ping-pong}

PingとPongメッセージは、WebSocket接続を維持するためにクライアントとサーバーによって自動的に送信されます。アプリケーションは`onPing`と`onPong`コールバックを使用してこれらのイベントをリッスンできます。

```swift
ws.onPing { ws in 
    // Pingを受信
}

ws.onPong { ws in
    // Pongを受信
}
```