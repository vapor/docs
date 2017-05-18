---
currentMenu: routing-group
---

# Route Groups

> 翻译：[@孟祥月_iOS](http://weibo.com/u/1750643861)

将路由分组在一起可以很容易地添加公共前缀，中间件或某个主机上的多个路由。
Route groups have two different forms: Group and Grouped.

### Group

Group (without the "ed" at the end) takes a closure that is passed a `GroupBuilder`.
Group (不以 “ed” 结尾) 使用一个带有 `GroupBuilder` 作为参数的闭包来组织路由。

```swift
drop.group("v1") { v1 in // 译者注： v1 类型 <RouteGroup<Responder, Droplet> 与上面有点出入
    v1.get("users") { request in
        // get the users
    }
}
```

### Grouped

Grouped 返回一个 `GroupBuilder`，并且你能够传递到其他地方。

```swift
let v1 = drop.grouped("v1")
v1.get("users") { request in
    // get the users
}
```

### Middleware

你可以为一组路由添加中间件，这个对于校验尤其有用。

```swift
drop.group(AuthMiddleware()) { authorized in
    authorized.get("token") { request in
        // has been authorized
    }
}
```

### Host

你能够限制在某个主机上的一组路由。

```
drop.group(host: "vapor.codes") { vapor
    vapor.get { request in
        // only responds to requests to vapor.codes
    }
}
```

### Chaining

组能够被串联（chained）在一起。

```swift
drop.grouped(host: "vapor.codes").grouped(AuthMiddleware()).group("v1") { authedSecureV1 in
    // add routes here
}
```
