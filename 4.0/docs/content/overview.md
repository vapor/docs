# Content

Vapor's content API allows you to easily encode / decode Codable structs to / from HTTP messages. [JSON](https://tools.ietf.org/html/rfc7159) encoding is used by default with out-of-the-box support for [URL-Encoded Form](https://en.wikipedia.org/wiki/Percent-encoding#The_application/x-www-form-urlencoded_type) and [Multipart](https://tools.ietf.org/html/rfc2388). The API is also configurable, allowing for you to add, modify, or replace encoding strategies for certain HTTP content types.

To understand how Vapor's content API works, you should first understand a few basics about HTTP messages. Take a look at the following example request.

```http
POST /greeting HTTP/1.1
content-type: application/json
content-length: 18

{"hello": "world"}
```

This request indicates that it contains JSON-encoded data using the `content-type` header and `application/json` media type. As promised, some JSON data follows after the headers in the body.

## Content Struct

The first step to decoding this HTTP message is creating a Codable type that matches the expected structure. 

```swift
struct Greeting: Content {
	var hello: String
}
```

Conforming the type to `Content` will automatically add conformance to `Codable` alongside additional utilities for working with the content API.

Once you have the content structure, you can decode it from the incoming request using `req.content`.

```swift
app.post("greeting") { req in 
	let greeting = try req.content.decode(Greeting.self)
	print(greeting.hello) // "world"
	return HTTPStatus.ok
}
```

The decode method uses the request's content type to find an appropriate decoder. If there is no decoder found, or the request does not contain the content type header, a `415` error will be thrown.

That means that this route automatically accepts all of the other supported content types, such as url-encoded form:

```http
POST /greeting HTTP/1.1
content-type: application/x-www-form-urlencoded
content-length: 11

hello=world
```

## Supported Media Types

Below are the media types the content API supports by default.

|name|header value|media type|
|-|-|-|
|JSON|application/json|`.json`|
|Multipart|multipart/form-data|`.formData`|
|URL-Encoded Form|application/x-www-form-urlencoded|`.urlEncodedForm`|
|Plaintext|text/plain|`.plainText`|
|HTML|text/html|`.html`|

Not all media types support all Codable features. For example, JSON does not support top-level fragments and Plaintext does not support nested data.

## Request Query

## Client Response