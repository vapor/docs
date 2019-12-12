# Content

Vapor's content API allows you to easily encode / decode Codable structs to / from HTTP messages. [JSON](https://tools.ietf.org/html/rfc7159) encoding is used by default with out-of-the-box support for [URL-Encoded Form](https://en.wikipedia.org/wiki/Percent-encoding#The_application/x-www-form-urlencoded_type), [Multipart](https://tools.ietf.org/html/rfc2388), and plaintext. The API is also configurable, allowing for you to add, modify, or replace encoding strategies for certain HTTP content types.

To understand how Vapor's content API works, you should first understand a few basics about HTTP messages. Take a look at the following example response.

```http
HTTP/1.1 200 OK
content-type: application/json
content-length: 18

{"hello": "world"}
```

This response indicates that it contains JSON-encoded data using the `content-type` header and `application/json` media type. As promised, some JSON data follows after the headers.

## Content Struct

The first step to decoding this HTTP message is creating a Codable type that matches the expected structure. 

```swift
struct Greeting: Content {
	var hello: String
}
```

Conforming the type to `Content` will automatically add conformance to `Codable` alongside additional utilities for working with the content API.