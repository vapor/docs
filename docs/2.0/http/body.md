# Body

The `HTTP.Body` represents the payload of an `HTTP.Message`, and is used to pass the underlying data. Some examples of this in practice would be `JSON`, `HTML` text, or the bytes of an image. Let's look at the implementation:

```swift
public enum Body {
    case data(Bytes)
    case chunked((ChunkStream) throws -> Void)
}
```

## Data Case

The `data` case is by far the most common use for a `Body` in an `HTTP.Message`. It is simply an array of bytes. The serialization protocol or type associated with these bytes is usually defined by the `Content-Type` header. Let's look at some examples.

### Application/JSON

If our `Content-Type` header contains `application/json`, then the underlying bytes represent serialized JSON.

```swift
if let contentType = req.headers["Content-Type"], contentType.contains("application/json"), let bytes = req.body.bytes {
  let json = try JSON(bytes: bytes)
  print("Got JSON: \(json)")
}
```

### Image/PNG

If our `Content-Type` contains `image/png`, then the underlying bytes represent an encoded png.

```swift
if let contentType = req.headers["Content-Type"], contentType.contains("image/png"), let bytes = req.body.bytes {
  try database.save(image: bytes)
}
```

## Chunked Case

The `chunked` case only applies to outgoing `HTTP.Message`s in Vapor. It is traditionally a responder's role to collect an entire chunked encoding before passing it on. We can use this to send a body asynchronously.

```swift
let body: Body = Body.chunked(sender)
return Response(status: .ok, body: body)
```

We can implement this manually, or use Vapor's built in convenience initializer for chunked bodies:

```swift
return Response(status: .ok) { chunker in
  for name in ["joe", "pam", "cheryl"] {
      sleep(1)
      try chunker.send(name)
  }

  try chunker.close()
}
```

> Make sure to call `close()` before the chunker leaves scope.

## BodyRepresentable

In addition to the concrete `Body` type, as is common in Vapor, we also have wide support for `BodyRepresentable`. This means objects that we're commonly converting to `Body` type can be used interchangeably. For example:

```swift
return Response(body: "Hello, World!")
```

In the above example, string is converted to bytes and added to the body.

> In practice, it is better to use `return "Hello, World!"`. Vapor will automatically be able to set the `Content-Type` to appropriate values.

Let's look at how it's implemented:

```swift
public protocol BodyRepresentable {
    func makeBody() -> Body
}
```

### Custom

We can conform our own types to this as well where applicable. Let's pretend we have a custom data type, `.vpr`. Let's conform our `VPR` file type model:

```swift
extension VPRFile: HTTP.BodyRepresentable {
  func makeBody() -> Body {
    // collect bytes
    return .data(bytes)
  }
}
```

> You may have noticed above, that the protocol throws, but our implementation does not. This is completely valid in Swift and will allow you to not throw if you're ever calling the function manually.

Now we're able to include our `VPR` file directly in our `Responses`.

```swift
drop.get("files", ":file-name") { request in
  let filename = try request.parameters.extract("file-name") as String
  let file = VPRFileManager.fetch(filename)
  return Response(status: .ok, headers: ["Content-Type": "file/vpr"], body: file)
}
```

In practice, if we're repeating this often, we'll probably conform `VPRFile` directly to `ResponseRepresentable`

```swift
extension VPRFile: HTTP.ResponseRepresentable {
  func makeResponse() -> Response {
    return Response(
      status: .ok,
      headers: ["Content-Type": "file/vpr"],
      body: file
    )
  }
}
```

Here's our above example now:

```swift
drop.get("files", ":file-name") { request in
  let filename = try request.parameters.extract("file-name") as String
  return VPRFileManager.fetch(filename)
}
```

We could also use type-safe routing to make this even more concise:

```swift
drop.get("files", String.self) { request, filename in
  return VPRFileManager.fetch(filename)
}
```
