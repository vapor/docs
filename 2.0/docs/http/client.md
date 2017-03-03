---
currentMenu: http-client
---

> Module: `import HTTP`

# Client

The client provided by `HTTP` is used to make outgoing requests to remote servers. Let's look at a simple outgoing request.

## QuickStart

Let's jump right in to make a simple HTTP Request. Here's a basic `GET` request using your Vapor `Droplet`.

```swift
let query = ...
let spotifyResponse = try drop.client.get("https://api.spotify.com/v1/search?type=artist&q=\(query)")
print(spotifyR)
```

### Clean Up

The url above can be a little tricky to read, so let's use the query parameter to clean it up a little bit:

```swift
try drop.client.get("https://api.spotify.com/v1/search", query: ["type": "artist", "q": query])
```

### Continued

In addition to `GET` requests, Vapor's client provides support for most common HTTP functions. `GET`, `POST`, `PUT`, `PATCH`, `DELETE`

### POST as json
```swift
try drop.client.post("http://some-endpoint/json", headers: ["Content-Type": "application/json"], body: myJSON.makeBody())
```

### POST as x-www-form-urlencoded
```swift
try drop.client.post("http://some-endpoint", headers: [
  "Content-Type": "application/x-www-form-urlencoded"
], body: Body.data( Node(node: [
  "email": "mymail@vapor.codes"
]).formURLEncoded()))               
```

### Full Request

To access additional functionality or custom methods, use the underlying `request` function directly.

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

The `Config/clients.json` file can be used to modify the client's settings.

### TLS

Host and certificate verification can be disabled.

> Note: Use extreme caution when modifying these settings.

```json
{
    "tls": {
        "verifyHost": false,
        "verifyCertificates": false
    }
}
```

### Mozilla

The Mozilla certificates are included by default to make fetching content from secure sites easy.

```json
{
    "tls": {
        "certificates": "mozilla"
    }
}
```

## Advanced

In addition to our Droplet, we can also use and interact with the `Client` manually. Here's how our default implementation in Vapor looks:

```swift
let response = try Client<TCPClientStream>.get("http://some-endpoint/mine")
```

The first thing we likely noticed is `TCPClientStream` being used as a Generic value. This will be the underlying connection that the `HTTP.Client` can use when performing the request. By conforming to the underlying `ClientStream`, an `HTTP.Client` can accept custom stream implementations seamlessly.

## Save Connection

Up to this point, we've been interacting with the Client via `class` or `static` level functions. This allows us to end the connection upon a completed request and is the recommended interaction for most use cases. For some advanced situations, we may want to reuse a connection. For these, we can initialize our client and perform multiple requests like this.

```swift
let pokemonClient = try drop?.client.make(scheme: "http", host: "pokeapi.co")
for i in 0...1 {
    let response = try pokemonClient?.get(path: "/api/v2/pokemon/", query: ["limit": 20, "offset": i])
    print("response: \(response)")
}
```

## ClientProtocol

Up to this point, we've focused on the built in `HTTP.Client`, but users can also include their own customized clients by conforming to `HTTP.ClientProtocol`. Let's look at the implementation:

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

By conforming to these underlying functions, we immediately gain access to the public `ClientProtocol` apis we viewed above.

## Customize Droplet

If we've introduced a custom conformance to `HTTP.ClientProtocol`, we can pass this into our droplet without changing the underlying behavior in our application.

For example:

```swift
let drop = Droplet()

drop.client = MyCustomClient.self
```

Going forward, all of your calls to `drop.client` will use `MyCustomClient.self`:

```swift
drop.client.get(... // uses `MyCustomClient`
```
