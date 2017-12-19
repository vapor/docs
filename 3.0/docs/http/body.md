# HTTPBody

HTTPBody is a type that contains the raw representation of a [Request](request.md) or [Response](response.md). It's contents are related to the `Content-Type` header.

Body can contain, but is not limited to `Data`, `String`, `DispatchData` or binary streams.
Binary streams will be chunk-encoded in HTTP/1.

## Creating a Body

Empty bodies can be created using the empty initializer `Body()`.
Alternatively you can provide `Data` or `DispatchData` as the content of the body.

## HTTPBodyRepresentable

If you want to serialize your data to a body using a predefined format such as JSON or XML, look into [`Content`](../getting-started/content.md) first.

When adding a new struct/class that can be serialized to a raw Body as part of a Request or Response you can consider implementing the `HTTPBodyRepresentable` protocol.

Below is how String is implemented.

```swift
/// String can be represented as an HTTP body.
extension String: HTTPBodyRepresentable {
    /// See BodyRepresentable.makeBody()
    public func makeBody() throws -> HTTPBody {

    }
}
```

Although often unnecessary it is possible to throw an error here if the creation of the body failed.
