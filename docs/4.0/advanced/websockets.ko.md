# 웹소켓(WebSockets)

[웹소켓](https://en.wikipedia.org/wiki/WebSocket)은 클라이언트와 서버 간의 양방향 통신을 가능하게 합니다. 요청과 응답 패턴을 가지는 HTTP와 달리, 웹소켓 피어(peer)는 양쪽 방향으로 임의의 개수의 메시지를 보낼 수 있습니다. Vapor의 웹소켓 API를 사용하면 메시지를 비동기적으로 처리하는 클라이언트와 서버를 모두 만들 수 있습니다.

## 서버

라우팅 API를 사용해 기존 Vapor 애플리케이션에 웹소켓 엔드포인트를 추가할 수 있습니다. `get`이나 `post`를 사용하는 것처럼 `webSocket` 메서드를 사용하면 됩니다.

```swift
app.webSocket("echo") { req, ws in
    // Connected WebSocket.
    print(ws)
}
```

웹소켓 라우트도 일반 라우트처럼 미들웨어로 그룹화하거나 보호할 수 있습니다.

웹소켓 핸들러는 들어오는 HTTP 요청을 받는 것에 더해, 새로 수립된 웹소켓 연결도 받습니다. 이 웹소켓을 사용해 메시지를 보내고 읽는 방법에 대한 자세한 내용은 아래를 참고하세요.

## 클라이언트

원격 웹소켓 엔드포인트에 연결하려면 `WebSocket.connect`를 사용하세요.

```swift
WebSocket.connect(to: "ws://echo.websocket.org", on: eventLoop) { ws in
    // Connected WebSocket.
    print(ws)
}
```

`connect` 메서드는 연결이 수립되면 완료되는 future를 반환합니다. 연결이 되면, 전달된 클로저가 새로 연결된 웹소켓과 함께 호출됩니다. 이 웹소켓을 사용해 메시지를 보내고 읽는 방법에 대한 자세한 내용은 아래를 참고하세요.

## 메시지

`WebSocket` 클래스에는 메시지를 보내고 받는 메서드는 물론, 연결 종료와 같은 이벤트를 수신할 수 있는 메서드도 있습니다. 웹소켓은 텍스트와 바이너리, 두 가지 프로토콜로 데이터를 전송할 수 있습니다. 텍스트 메시지는 UTF-8 문자열로 해석되며, 바이너리 데이터는 바이트 배열로 해석됩니다.

### 보내기

메시지는 웹소켓의 `send` 메서드를 사용해 보낼 수 있습니다.

```swift
ws.send("Hello, world")
```

이 메서드에 `String`을 전달하면 텍스트 메시지가 전송됩니다. `[UInt8]`을 전달하면 바이너리 메시지를 보낼 수 있습니다.

```swift
ws.send([1, 2, 3])
```

메시지 전송은 비동기적으로 이루어집니다. `send` 메서드에 `EventLoopPromise`를 전달하면 메시지 전송이 완료되거나 실패했을 때 알림을 받을 수 있습니다.

```swift
let promise = eventLoop.makePromise(of: Void.self)
ws.send(..., promise: promise)
promise.futureResult.whenComplete { result in
    // Succeeded or failed to send.
}
```

`async`/`await`를 사용한다면, `await`를 사용해 비동기 작업이 완료될 때까지 기다릴 수 있습니다.

```swift
try await ws.send(...)
```

### 받기

들어오는 메시지는 `onText`와 `onBinary` 콜백을 통해 처리됩니다.

```swift
ws.onText { ws, text in
    // String received by this WebSocket.
    print(text)
}

ws.onBinary { ws, binary in
    // [UInt8] received by this WebSocket.
    print(binary)
}
```

참조 순환(reference cycle)을 방지하기 위해, 웹소켓 자신이 이러한 콜백의 첫 번째 매개변수로 전달됩니다. 데이터를 받은 후 웹소켓에 대해 작업을 수행하려면 이 참조를 사용하세요. 예를 들어, 응답을 보내려면 다음과 같이 합니다.

```swift
// Echoes received messages.
ws.onText { ws, text in
    ws.send(text)
}
```

## 닫기

웹소켓을 닫으려면 `close` 메서드를 호출하세요.

```swift
ws.close()
```

이 메서드는 웹소켓이 닫히면 완료되는 future를 반환합니다. `send`와 마찬가지로, 이 메서드에도 promise를 전달할 수 있습니다.

```swift
ws.close(promise: nil)
```

또는 `async`/`await`를 사용한다면 `await`를 사용하세요.

```swift
try await ws.close()
```

피어가 연결을 닫을 때 알림을 받으려면 `onClose`를 사용하세요. 이 future는 클라이언트와 서버 중 어느 한쪽이 웹소켓을 닫으면 완료됩니다.

```swift
ws.onClose.whenComplete { result in
    // Succeeded or failed to close.
}
```

`closeCode` 프로퍼티는 웹소켓이 닫힐 때 설정됩니다. 이를 사용해 피어가 왜 연결을 닫았는지 확인할 수 있습니다.

## Ping / Pong

웹소켓 연결을 유지하기 위해 클라이언트와 서버는 ping과 pong 메시지를 자동으로 전송합니다. 애플리케이션에서는 `onPing`과 `onPong` 콜백을 사용해 이러한 이벤트를 수신할 수 있습니다.

```swift
ws.onPing { ws in 
    // Ping was received.
}

ws.onPong { ws in
    // Pong was received.
}
```
