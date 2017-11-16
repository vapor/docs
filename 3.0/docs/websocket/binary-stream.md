# Binary Streams

WebSockets have separate [text](text-stream.md) and binary data flows.

Sending binary input to a WebSocket sends it to the remote. Listening for binary on a WebSocket receives binary (and binary continuation) data from clients.

## Sending binary data

Sending a `Data` or `ByteBuffer` using a WebSocket sends it to the remote.

```swift
webSocket.send(byteBuffer)
webSocket.send(data)
```

## Receiving binary data

Binary data can be read as a `ByteBuffer` using the following function. Only one closure can read at a time.

```swift
webSocket.onBinary { byteBuffer in
  // use the `ByteBuffer`
}
```

Binary data can also, instead, be used as Foundation's `Data`. This is less efficient than `ByteBuffer` but often easier to use.

```swift
webSocket.onData { data in
  // use the `Data`
}
```

You can only use one of the two listeners at a time.
