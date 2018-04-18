# Using HTTPClient

HTTP clients send requests to remote HTTP servers which then generate and return responses. HTTP clients are usually only active for a matter of seconds to minutes and may send one or more requests. The [`HTTPClient`](https://api.vapor.codes/http/latest/HTTP/Classes/HTTPClient.html) type is what powers Vapor's higher-level client. This short guide will show you how to send HTTP requests to servers manually.


!!! tip
	If you are using Vapor, you probably don't need to use HTTP's APIs directly. Refer to [Vapor &rarr; Client](../vapor/client.md) for the more convenient APIs.

For this example, we will fetch Vapor's homepage. The first step is to create a connected HTTP client. Use the static [`connect(...)`](https://api.vapor.codes/http/latest/HTTP/Classes/HTTPClient.html#/s:4HTTP10HTTPClientC7connectXeXeFZ) method to do this.

```swift
// Connect a new client to the supplied hostname.
let client = try HTTPClient.connect(hostname: "vapor.codes", on: ...).wait()
print(client) // HTTPClient
// Create an HTTP request: GET /
let httpReq = HTTPRequest(method: .GET, url: "/")
// Send the HTTP request, fetching a response
let httpRes = try client.send(httpReq).wait()
print(httpRes) // HTTPResponse
```

Take note that we are passing the _hostname_. This is different from a full URL. You can use `URL` and `URLComponents` from Foundation to parse out a hostname. Vapor's convenience APIs do this automatically.

!!! warning
    This guide assumes you are on the main thread. Don't use `wait()` if you are inside of a route closure. See [Async &rarr; Overview](../async/overview/#blocking) for more information.

After we have a connected HTTP client, we can send an [`HTTPRequest`](https://api.vapor.codes/http/latest/HTTP/Structs/HTTPRequest.html) using [`send(...)`](https://api.vapor.codes/http/latest/HTTP/Classes/HTTPClient.html#/s:4HTTP10HTTPClientC4sendXeXeF). This will return an  [`HTTPResponse`](https://api.vapor.codes/http/latest/HTTP/Structs/HTTPResponse.html) containing the headers and body sent back from the server. See [HTTP &rarr; Message](message.md) for more information on HTTP messages. 

## API Docs

That's it! Congratulations on making your first HTTP request. Check out the [API docs](https://api.vapor.codes/http/latest/HTTP/index.html) for more in-depth information about all of the available parameters and methods.