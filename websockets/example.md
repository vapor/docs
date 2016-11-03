---
currentMenu: websockets-example
---

# Using WebSockets

Below are some examples of WebSockets in use.

## Droplet

Creating a WebSocket server with the Droplet is easy. WebSockets work by upgrading an HTTP request to a WebSocket connection.

Because of this, you should pick a URL for your WebSocket server to reside at. In this case, we use `/ws`.

```swift
import Vapor

let drop = Droplet()

drop.socket("ws") { req, ws in
    print("New WebSocket connected: \(ws)")

    // ping the socket to keep it open
    try background {
        if ws.state == .open {
            try? ws.ping()
            drop.console.wait(seconds: 10) // every 10 seconds
        }
    }

    ws.onText = { ws, text in
        print("Text received: \(text)")

        // reverse the characters and send back
        let rev = String(text.characters.reversed())
        try ws.send(rev.bytes)
    }

    ws.onClose = { ws, code, reason, clean in
        print("Closed.")
    }
}

drop.run()
```

To connect with a WebSocket client, you would open a connection to `ws://<ip>/ws`.

Here is an example using JavaScript.

```js

var ws = new WebSocket("ws://0.0.0.0:8080/ws")

ws.onmessage = function(msg) {
    console.log(msg)
}

ws.send('test')
```

The above will log `tset` (`test` reversed).

## Client

```Swift
import WebSockets

try WebSocket.connect(to: url) { ws in
    print("Connected to \(url)")

    ws.onText = { ws, text in
        print("[event] - \(text)")
    }

    ws.onClose = { ws, _, _, _ in
        print("\n[CLOSED]\n")
    }
}
```

## Server

```Swift
import HTTP
import WebSockets
import Transport

final class MyResponder: Responder {
    func respond(to request: Request) throws -> Response {
        return try request.upgradeToWebSocket { ws in
            print("[ws connected]")

            ws.onText = { ws, text in
                print("[ws text] \(text)")
                try ws.send("🎙 \(text)")
            }

            ws.onClose = { _, code, reason, clean in
                print("[ws close] \(clean ? "clean" : "dirty") \(code?.description ?? "") \(reason ?? "")")
            }
        }
    }
}

let port = 8080
let server = try Server<TCPServerStream, Parser<Request>, Serializer<Response>>(port: port)

print("Connect websocket to http://localhost:\(port)/")
try server.start(responder: MyResponder()) { error in
    print("Got server error: \(error)")
}
```
