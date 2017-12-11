# WebSocket Upgrading

Servers can upgrade HTTP requests to a WebSocket if the client indicated an upgrade.

## Determining an upgrade

You will need to `import WebSocket` for the upgrade functionality.

Create a basic `GET` route. WebSockets always connect with a GET [method](../http/method.md).

```swift
import WebSocket

drop.get("api/v1/websocket") { req in
  let shouldUpgrade = WebSocket.shouldUpgrade(for: req)
}
```

## Upgrading the connection

The WebSocket library can generate an appropriate [Response](../http/response.md) for you. You can return this in your route.

You will be able to set a handler inside `onUpgrade` in which a websocket will be returned after completion of the upgrade.

!!! warning
	Vapor does not retain the WebSocket. It is the responsibility of the user to keep the WebSocket active by means of strong references and pings.

```swift
if shouldUpgrade {
  let response = try WebSocket.upgradeResponse(for: req)

  response.onUpgrade = { client in
      let websocket = WebSocket(client: client)
      websocket.onText { text in
          let rev = String(text.reversed())
          websocket.send(rev)
      }
      websocket.onBinary { buffer in
          websocket.send(buffer)
      }
  }

  return response
}
```

## Using websockets

WebSockets are interacted with using [binary streams](binary-stream.md) or [text streams](text-stream.md).

All other information about websockets [is defined here.](websocket.md)
