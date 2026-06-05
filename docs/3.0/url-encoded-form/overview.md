# Using URL-Encoded Form

URL-Encoded Form is a widely-supported encoding on the web. It's most often used for serializing web forms sent via POST requests. This encoding is also used to send structured data in URL query strings.

It is a relatively efficient encoding for sending small amounts of data. However, all data must be percent-encoded making this encoding suboptimal for large amounts of data. See the [Multipart](../multipart/getting-started.md) encoding if you need to upload things like files.

!!! tip
    URL-Encoded Form integrates with [`Content`](https://api.vapor.codes/vapor/latest/Vapor/Protocols/Content.html) like all other encoding methods in Vapor. See [Vapor &rarr; Content](../vapor/content.md) for more information about the [`Content`](https://api.vapor.codes/vapor/latest/Vapor/Protocols/Content.html) protocol. 

Let's take a look at how to decode a `application/x-www-form-urlencoded` request. 

## Decode Body

Most often, you will be decoding `form-urlencoded`-encoded requests from a web form. Let's take a look at what one of these requests might look like. After that, we will take a look at what the HTML form for that request would look like.

### Request

Here is an example `form-urlencoded`-encoded request for creating a new user.

```http
POST /users HTTP/1.1
Content-Type: application/x-www-form-urlencoded

name=Vapor&age=3&luckyNumbers[]=5&luckyNumbers[]=7
```

You can see the `[]` notation is used to encode arrays. Your web form will need to use this notation as well.

### Form

There are many ways to create a `form-urlencoded`-encoded request, but the most common is an HTML web form. Here is what the HTML form for this request might have looked like.

```html
<form method="POST" action="/users">
    <input type="text" name="name">
    <input type="text" name="age">
    <input type="text" name="luckyNumbers[]">
    <input type="text" name="luckyNumbers[]">  
</form>
```

Since we are not specifying a special `enctype` attribute on the `<form>`, the browser will URL-encode the form by default. We are also providing two fields with the same name, `luckyNumbers[]`. This will let us send an array of values.

### Content

Now let's take a look at how we would handle this request in Vapor. The first step (as always with [`Content`](https://api.vapor.codes/vapor/latest/Vapor/Protocols/Content.html)) is to create a `Codable` struct that represents the data structure.

```swift
import Vapor

struct User: Content {
    var name: String
    var age: Int
    var luckyNumbers: [Int]
}
```

Now that we have our `User` struct, let's decode that request! We can use the [`ContentContainer`](https://api.vapor.codes/vapor/latest/Vapor/Structs/ContentContainer.html) to do this easily.

```swift
router.post("users") { req -> Future<HTTPStatus> in
    return try req.content.decode(User.self).map(to: HTTPStatus.self) { user in
        print(user.name) // "Vapor"
        print(user.age) // 3
        print(user.luckyNumbers) // [5, 7]
        return .ok
    }
}
```

Now when you post the form to `/users`, you should see the information printed in the console. Nice work!

## Encode Body

APIs encode `form-urlencoded` data much less often than they decode it. However, encoding is just as easy with Vapor. Using our same `User` struct from the previous example, here is how we can encode a `form-urlencoded`-encoded response.

```swift
router.get("multipart") { req -> User in
    let res = req.makeResponse()
    let user = User(name: "Vapor", age: 3, luckyNumbers: [5, 7])
    res.content.encode(user, as: .urlEncodedForm)
    return user
}
```

!!! tip
    If you set a default `MediaType` on your `Content` types, then you can return them directly in the route closure.

## URL Query

URL-Encoded Forms are also useful for sending structured data in the URL query string. This is widely used for sending data via GET requests where HTTP bodies are not allowed.

Let's take a look at how we can decode some search parameters from the query string.

```http
GET /users?name=Vapor&age=3 HTTP/1.1
```
The first step (as always with [`Content`](https://api.vapor.codes/vapor/latest/Vapor/Protocols/Content.html)) is to create a `Codable` struct that represents the data structure.

```swift
import Vapor

struct UsersFilters: Content {
    var name: String?
    var age: Int?
}
```

Here we are making both `name` and `age` optional since the route can be called without any flags to return all users.

Now that we have a `Codable` struct, we can decode the URL query string. The process is almost identical to decoding content, expect we use `req.query` instead of `req.content`.

```swift
router.get("users") { req -> Future<[User]> in
    let filters = try req.query.decode(UsersFilters.self)
    print(filters.name) // Vapor
    print(filters.age) //  3
    return // fetch users with filters
}
```

!!! tip
    Decoding the URL query string is not asynchronous because, unlike HTTP bodies, Vapor can be sure it is available when calling the route closure.



