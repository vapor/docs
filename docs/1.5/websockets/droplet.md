---
currentMenu: websockets-droplet
---

# Droplet WebSockets

Creating a WebSocket server with the Droplet is easy. WebSockets work by upgrading an HTTP request to a WebSocket connection.

Because of this, you should pick a URL for your WebSocket server to reside at. In this case, we use `/ws`.

```swift
import Vapor

let drop = Droplet()

drop.socket("ws") { req, ws in
    print("New WebSocket connected: \(ws)")

    // ping the socket to keep it open
    try background {
        while ws.state == .open {
            try? ws.ping()
            drop.console.wait(seconds: 10) // every 10 seconds
        }
    }

    ws.onText = { ws, text in
        print("Text received: \(text)")

        // reverse the characters and send back
        let rev = String(text.characters.reversed())
        try ws.send(rev)
    }

    ws.onClose = { ws, code, reason, clean in
        print("Closed.")
    }
}

drop.run()
```

To connect with a WebSocket client, you would open a connection to `ws://<ip>/ws`.

Here is an example using JavaScript.

```swift
var ws = new WebSocket("ws://0.0.0.0:8080/ws")

ws.onmessage = function(msg) {
    console.log(msg)
}

ws.onopen = function(event) {
    ws.send("test")
}
```

The above will log `tset` (`test` reversed).
