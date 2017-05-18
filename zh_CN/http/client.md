---
currentMenu: http-client
---

> Module: `import HTTP`

# Client

> 翻译：[@孟祥月_iOS](http://weibo.com/u/1750643861)

`HTTP` 提供的 client，可以用来向远程服务器发送请求。让我们看一个简单的发送请求的例子。

## QuickStart

让我们开始创建一个简单的 HTTP Request。这是使用你的 Vapor 的 `Droplet` 创建的基础的 `GET` request。

```swift
let query = ...
let spotifyResponse = try drop.client.get("https://api.spotify.com/v1/search?type=artist&q=\(query)")
print(spotifyR)
```

### Clean Up

上面的 url 读起来可能有点困难，所以我们使用 query 参数，使其变得更加清楚易读一些。

```swift
try drop.client.get("https://api.spotify.com/v1/search", query: ["type": "artist", "q": query])
```

### Continued

除了 `GET` 请求，Vapor 的 client 也支持大部分普通的 HTTP 方式，如：`GET`、 `POST`、 `PUT`、 `PATCH`、`DELETE`。

### POST as json
```swift
let bytes = myJSON.makeBytes()
try drop.client.post("http://some-endpoint/json", headers: ["Auth": "Token my-auth-token"], body: .data(jsonBytes))
```

### POST as x-www-form-urlencoded
```swift
try drop.client.post("http://some-endpoint", headers: [
  "Content-Type": "application/x-www-form-urlencoded"
], body: Body.data( Node([
  "email": "mymail@vapor.codes"
]).formURLEncoded()))               
```

### Full Request

要访问其他功能或自定义方法，请直接使用底层的 `request` 函数。

```swift
public static func get(_ method: Method,
                       _ uri: String,
                       headers: [HeaderKey: String] = [:],
                       query: [String: CustomStringConvertible] = [:],
                       body: Body = []) throws -> Response
```

For example:

```swift
try drop.client.request(.other(method: "CUSTOM"), "http://some-domain", headers: ["My": "Header"], query: ["key": "value"], body: [])
```

## Config

`Config/clients.json` 可以用来修改 client 的配置。

### TLS

主机和证书（Host 和 certificate）校验可以被关闭。

> 注意：修改这些设置时请格外小心

```json
{
    "tls": {
        "verifyHost": false,
        "verifyCertificates": false
    }
}
```

### Mozilla

Mozilla 证书是默认包含的，使从安全网站（secure sites）获取内容变得容易。

```json
{
    "tls": {
        "certificates": "mozilla"
    }
}
```

## 高级 （Advanced）

除了我们的 Droplet，我们也可以直接使用 `Client`。这里看看 Vapor 中的默认实现：

```swift
let response = try Client<TCPClientStream>.get("http://some-endpoint/mine")
```

第一点我们注意到 `TCPClientStream` 被用作一个泛型值。这是 HTTP.Client 在执行请求时可以使用的底层连接。通过实现底层的 `ClientStream` 协议，`HTTP.Client `可以无缝地接受自定义流实现（an `HTTP.Client` can accept custom stream implementations seamlessly.）。

## 保存连接 （Save Connection）

到现在，我们已经通过 `class` 或者 `static` 方法与 Client 交互过了。这允许我们在完成的请求后结束连接，并且是大多数用例的建议交互。对于一些高级场景，我们可能想要重用连接。对于这个，我们可以初始化我们的 client，然后执行多个 request，类似如下：

```swift
let pokemonClient = try drop?.client.make(scheme: "http", host: "pokeapi.co")
for i in 0...1 {
    let response = try pokemonClient?.get(path: "/api/v2/pokemon/", query: ["limit": 20, "offset": i])
    print("response: \(response)")
}
```

## ClientProtocol

到现在为止，我们主要关注内建的 `HTTP.Client`。但是用户也可以通过实现  `HTTP.ClientProtocol` 协议，自定义他们自己的 client。让我们看一下实现：

```swift
public protocol Responder {
    func respond(to request: Request) throws -> Response
}

public protocol Program {
    var host: String { get }
    var port: Int { get }
    var securityLayer: SecurityLayer { get }
    // default implemented
    init(host: String, port: Int, securityLayer: SecurityLayer) throws
}

public protocol ClientProtocol: Program, Responder {
    var scheme: String { get }
    var stream: Stream { get }
    init(scheme: String, host: String, port: Int, securityLayer: SecurityLayer) throws
}
```

通过实现这些底层函数，我们能立即访问我们上面看到 `ClientProtocol` 的公共 api。

## 自定义 Droplet （Customize Droplet）

如果我们引入了一个自定义实现了 `HTTP.ClientProtocol` 协议的 client，我们可以把它传递到我们的 droplet 中，而不用去修改我们应用程序中其他行为。

For example:

```swift
let drop = Droplet()

drop.client = MyCustomClient.self
```

Going forward, all of your calls to `drop.client` will use `MyCustomClient.self`:

```swift
drop.client.get(... // uses `MyCustomClient`
```
