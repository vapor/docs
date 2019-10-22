# Routing

Routing is the process of finding the appropriate request handler for an incoming request. At the core of Vapor's routing is a high-performance, trie-node router from [RoutingKit](https://github.com/vapor/routing-kit).

To understand how routing works in Vapor, you must first understand the basics of an HTTP request. Take a look at the following example request.

```http
GET /hello/vapor HTTP/1.1
host: vapor.codes
content-length: 0
```

This is a simple `GET` HTTP request to the URL `/hello/vapor`. This is the kind of HTTP request your browser would make if you pointed it to the following URL.

```
http://vapor.codes/hello/vapor
```

## HTTP Verb

The first part of the request is the HTTP verb. `GET` is the most common HTTP verb, but there are several you will use often. These HTTP verbs are often associated with [CRUD](https://en.wikipedia.org/wiki/Create,_read,_update_and_delete) semantics.

|verb|crud|
|-|-|
|`GET`|Read|
|`POST`|Create|
|`PUT`|Replace|
|`PATCH`|Update|
|`DELETE`|Delete|

## Request Path

Right after the HTTP verb is the request's URI. This consists of a path starting with `/` and an optional query string after `?`. The HTTP verb and path are what Vapor uses to route requests.

After the HTTP verb and URI is the HTTP version followed by zero or more headers and finally a body. Since this is a `GET` request, it does not have a body. 

## Router Methods

Let's take a look at how this request could be handled in Vapor. 

```swift
app.get("hello", "vapor") { req in 
    return "Hello, vapor!"
}
```

All of the common HTTP verbs are available as methods on `Application`. They accept one or more string arguments that represent the request's path separated by `/`. 

Note that you could also write this using `on` followed by the verb.

```swift
app.on(.GET, "hello", "vapor") { ... }
```

With this route registered, the example HTTP request from above will result in the following HTTP response.

```http
HTTP/1.1 200 OK
content-length: 13
content-type: text/plain; charset=utf-8

Hello, vapor!
```

## Route Parameters

Now that we've successfully routed a request based on the HTTP verb and path, let's try making the path dynamic. Notice that the name "vapor" is hardcoded in both the path and the response. Let's make this dynamic so that you can visit `/hello/<any name>` and get a response.

```swift
app.get("hello", ":name") { req -> String in
    let name = req.parameters.get("name")!
    return "Hello, \(name)!"
}
```

By using a path component prefixed with `:`, we indicate to the router that this is a dynamic component. Any string supplied here will now match this route. We can then use `req.parameters` to access the value of the string.

!!! tip
    We can be sure that `req.parameters.get` will never return `nil` here since our route path includes `:name`. However, if you are accessing route parameters in middleware or in code triggered by multiple routes, you will want to handle the possibility of `nil`.

If you run the example request again, you'll still get a response that says hello to vapor. However, you can now include any name after `/hello/` and see it included in the response. Let's try `/hello/bob`.

```http
GET /hello/bob HTTP/1.1
content-length: 0
```
```http
HTTP/1.1 200 OK
content-length: 13
content-type: text/plain; charset=utf-8

Hello, bob!
```

Now that you understand the basics, check out each section to learn more about parameters, groups, and more.
