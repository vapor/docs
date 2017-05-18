---
currentMenu: websockets-custom
---

# Custom WebSockets

> 翻译：[@孟祥月_iOS](http://weibo.com/u/1750643861)

下面是一些使用底层引擎包（Engine package）的 WebSockets 的例子。

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
