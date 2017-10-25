# Body

Body contains the bytes transmitted for a [Request](request.md) or [Response](response.md). It's contents are related to the `Content-Type` header.

Body is a binary blob but can contain text like HTML, JSON or another text-based format.
It can also contain binary data such as images, ZIP and other files.

## Creating a Body

Empty bodies can be created using the empty initializer `Body()`.
Alternatively you can provide `Data` or `DispatchData` as the content of the body.

## BodyRepresentable

When adding a new struct/class that can be serialized to a Body as part of a Request or Response you can consider implementing the `BodyRepresentable` protocol. Below is how String is implemented.

```swift
/// String can be represented as an HTTP body.
extension String: BodyRepresentable {
    /// See BodyRepresentable.makeBody()
    public func makeBody() throws -> Body {
        guard let data = self.data(using: .utf8) else {
            throw Error(identifier: "string-body-conversion", reason: "Converting a String to an HTTP Body failed.")
        }

        return Body(data)
    }
}
```

The protocol requires the implementation of the `makeBody` function that creates a new `Body`.

Although often unnecessary it is possible to throw an error here if the creation of the body failed.
