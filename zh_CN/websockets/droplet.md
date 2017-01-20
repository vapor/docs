---
currentMenu: websockets-droplet
---

# Droplet WebSockets

> 翻译：[@孟祥月_iOS](http://weibo.com/u/1750643861)

使用 Droplet 创建一个 WebSocket 服务器是简单的。WebSockets通过将 HTTP 请求升级到 WebSocket 连接来工作。

由于这个，您应该为您的 WebSocket 服务器选择一个属于它的 URL。在这个例子中，我们使用 `/ws`。

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

要使用 WebSocket client 连接它，你应该与 `ws://<ip>/ws` 建立一个连接。

这里有一个使用 JavaScript 的例子。

```swift
var ws = new WebSocket("ws://0.0.0.0:8080/ws")

ws.onmessage = function(msg) {
    console.log(msg)
}

ws.onopen = function(event) {
    ws.send("test")
}
```

上面的代码将会输入 `tset` （倒序后的 `test`）。
