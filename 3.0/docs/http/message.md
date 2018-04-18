# Using HTTPMessage

There are two types of HTTP messages: [`HTTPRequest`](#fixme) and [`HTTPResponse`](#fixme). For the most part they are very similar, but there are a couple of differences. The first part of this guide will explain the common properties, followed by the unique ones.

Here is what a generic, encoded HTTP message looks like:

```http
<start line>
Content-Length: 5
Content-Type: text/plain

hello
```

The start-line is omitted since it varies between requests and responses.

## Headers

```http
Content-Length: 5
Content-Type: text/plain
```

Every HTTP message has a collection of headers. Headers contain metadata about the message and help to explain what is in the message's body. 

There must be at least a `"Content-Length"` or `"Transfer-Encoding"` header to define how long the message's body is. There is almost always a `"Content-Type"` header that explains what _type_ of data the body contains. There are many other common headers such as `"Date"` which specifies when the message was created, and more.

You can access an HTTP message's headers using the `headers` property.

```swift
let message: HTTPMessage ...
message.headers.firstValue(for: .contentLength) // 5
```

If you are interacting with common HTTP headers, you can use the convenience HTTP names instead of a raw `String`.

## Body

Coming soon.
