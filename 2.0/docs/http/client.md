# Client

The client provided by `HTTP` is used to make outgoing requests to remote servers. Let's look at a simple outgoing request.

## QuickStart

Let's jump right in to make a simple HTTP Request. Here's a basic `GET` request using your Vapor `Droplet`.

```swift
let query = "..."
let res = try drop.client.get("https://api.spotify.com/v1/search?type=artist&q=\(query)")
print(res)
```

### Clean Up

The url above can be a little tricky to read, so let's use the query parameter to clean it up a little bit:

```swift
let res = try drop.client.get("https://api.spotify.com/v1/search", query: [
    "type": "artist", 
    "q": query
])
```

### Continued

In addition to `GET` requests, Vapor's client provides support for most common HTTP functions. `GET`, `POST`, `PUT`, `PATCH`, `DELETE`

### Headers

You can also add additional headers to the request.

```swift
try drop.client.get("http://some-endpoint/json", headers: [
    "API-Key": "vapor123"
])
```

### Custom Request

You can ask the client to respond to any `Request` that you create. 
This is useful if you need to add JSON or FormURLEncoded data to the request.

```swift
let req = Request(method: .post, uri: "http://some-endpoint")
req.formURLEncoded = Node(node: [
    "email": "mymail@vapor.codes"
])

try drop.client.respond(to: req)
```

## Re-usable Connection

Up to this point, we've been using `drop.client` which is a `ClientFactory`. This creates a new client and TCP connection for each request.

For more better performance, you can create an re-use a single client.

```swift
let pokemonClient = try drop.client.makeClient(
    scheme: "http", 
    host: "pokeapi.co",
    securityLayer: .none
)

for i in 0...1 {
    let response = try pokemonClient.get("/api/v2/pokemon/", query: [
        "limit": 20, 
        "offset": i
    ])
    print("response: \(response)")
}
```

!!! note
    Clients created using `.makeClient` can not connect to a different server after initialization. (Proxy servers are an exception)

## Proxy

The `drop.client` can be configured to use a proxy by default.

`Config/client.json`
```json
{
    "proxy": {
        "hostname": "google.com", 
        "port": 80,
        "securityLayer": "none"
    }
}
```

For the above example, all requests sent to `drop.client.get(...)` would be proxied through google.com.
