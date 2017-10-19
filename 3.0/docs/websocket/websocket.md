# WebSocket

WebSockets are a type of connection that can be instantiated by upgrading an existing HTTP/1 connection. They're used to dispatch notifications and communicate real-time binary and textual Data.

## Using websockets

WebSockets are interacted with using [binary streams](binary-stream.md) or [text streams](text-stream.md).

### Errors

Any error in a WebSocket will close the connection.
