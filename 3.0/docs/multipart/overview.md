# Using Multipart

Multipart is a widely-supported encoding on the web. It's most often used for serializing web forms, especially ones that contain rich media like images. It allows for arbitrary data to be encoded in each part thanks to a unique delimiter _boundary_ that is defined separately. This boundary is guaranteed by the client to not appear anywhere in the data.

Multipart is a powerful encoding, however it is rarely used in its base format. Most commonly, `multipart/form-data` is used. This encoding adds a `"name"` property to each part of the multipart data. This is required for serializing web forms. For the rest of this guide, assume we are talking about `multipart/form-data` unless otherwise specified.

!!! tip
    Multipart integrates with [`Content`](https://api.vapor.codes/vapor/latest/Vapor/Protocols/Content.html) like all other encoding methods in Vapor. See [Vapor &rarr; Content](../vapor/content.md) for more information about the [`Content`](https://api.vapor.codes/vapor/latest/Vapor/Protocols/Content.html) protocol. 

Let's take a look at how to decode a `multipart/form-data`-encoded request.

## Decode

Most often, you will be decoding `multipart/form-data`-encoded requests from a web form. Let's take a look at what one of these requests might look like. After that, we will take a look at what the HTML form for that request would look like.

### Request

Here is an example `multipart/form-data`-encoded request for creating a new user.

```http
POST /users HTTP/1.1
Content-Type: multipart/form-data; boundary=123

--123
Content-Disposition: form-data; name="name"

Vapor
--123
Content-Disposition: form-data; name="age"

3
--123
Content-Disposition: form-data; name="image"; filename="droplet.png"

<contents of image>
--123--
```

You can see the multipart data uses a _boundary_ (in this case it is `"123"`) to separate the data. This will usually be a longer string. The client sending a multipart-encoded request must ensure that the boundary it supplies does not appear anywhere in the content it is sending you. That's what allows this encoding to be used to send things like files.

### Form

There are many ways to create a multipart-encoded request, but the most common is an HTML web form. Here is what the HTML form for this request might have looked like.

```html
<form method="POST" action="/users" enctype="multipart/form-data">
    <input type="text" name="name">
    <input type="text" name="age">
    <input type="file" name="image">
</form>
```

Take note of the `enctype` attribute on the `<form>` as well as the `file` type input. This is what allows us to send files via the web form.

### Content

Now let's take a look at how we would handle this request in Vapor. The first step (as always with [`Content`](https://api.vapor.codes/vapor/latest/Vapor/Protocols/Content.html)) is to create a `Codable` struct that represents the data structure.

```swift
import Vapor

struct User: Content {
    var name: String
    var age: Int
    var image: Data
}
```

!!! tip
    You can use [`File`](https://api.vapor.codes/core/latest/Core/Structs/File.html) instead of `Data` if you would also like to access the filename.

Now that we have our `User` struct, let's decode that request! We can use the [`ContentContainer`](https://api.vapor.codes/vapor/latest/Vapor/Structs/ContentContainer.html) to do this easily.

```swift
router.post("users") { req -> Future<HTTPStatus> in
    return try req.content.decode(User.self).map(to: HTTPStatus.self) { user in
        print(user.name) // "Vapor"
        print(user.age) // 3
        print(user.image) // Raw image data
        return .ok
    }
}
```

Now when you post the form to `/users`, you should see the information printed in the console. Nice work!

## Encode

APIs encode multipart data much less often than they decode it. However, encoding is just as easy with Vapor. Using our same `User` struct from the previous example, here is how we can encode a multipart-encoded response.

```swift
router.get("multipart") { req -> User in
    let res = req.makeResponse()
    let user = User(name: "Vapor", age: 3, image: Data(...))
    res.content.encode(user, as: .formData)
    return user
}
```

!!! tip
    If you set a default `MediaType` on your `Content` types, then you can return them directly in the route closure.

## Parsing & Serializing

The Multipart package also offers APIs for parsing and serializing `multipart/form-data` data without using `Codable`. Check out the [API Docs](https://api.vapor.codes/multipart/latest/Multipart/index.html) for more information on using those APIs.

