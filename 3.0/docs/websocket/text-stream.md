# Text Streams

WebSockets have separate text and [binary](binary-stream.md) data flows.

Sending text input to a WebSocket sends it to the remote. Listening for text on a WebSocket receives text data from clients.

## Sending strings

Sending a `String` using a WebSocket sends it to the remote.

```swift
webSocket.send(string)
```

## Receiving strings

String data can be read using the following function. Only one closure can read at a time.

```swift
webSocket.onText { text in
  // use the `String`
}
```
