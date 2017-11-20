# HTTP Client

HTTP Clients are often used to communicate with external APIs such as PayPal, Stripe or Mailgun.

## Connecting

Connecting only requires a hostname and a boolean indicating if you want to use SSL. For almost every use case it is recommended to use SSL. If you're processing any sensitive data such as payments, emails and other personal data you will need to use SSL by setting it to `true`.

HTTP clients require a [Worker](../async/worker.md), too, so it can run on the current [EventLoop](../concepts/async.md)

```swift
// Future<HTTPClient>
 let client = try HTTPClient.connect(
    to: "example.com",
    ssl: true,
    worker: worker
 )
```

You can override the port by specifying a custom port using the following parameters:

```swift
// Future<HTTPClient>
 let client = try HTTPClient.connect(
    to: "localhost",
    port: 8080,
    ssl: false,
    worker: worker
 )
```

## Sending Requests

From here, you can send [Requests](../http/request.md). You can only send one request at a time. Sending a request before a [Response](../http/response.md) has been received has unpredictable consequences.

```swift
// Future<Response>
let response = client.flatMap { connectedClient in
  let request = Request(
    method: .get,
    uri: "https://example.com/"
  )

  return connectedClient.send(request: request)
}
```
