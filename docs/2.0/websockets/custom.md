!!! warning
    This section may contain outdated information.

# Custom WebSockets

Below are some examples of WebSockets using the underlying Engine package.

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
