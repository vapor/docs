---
currentMenu: auth-request
---

# Request

> 翻译：[@孟祥月_iOS](http://weibo.com/u/1750643861)

`Request` 的 `auth` 属性，让你能够认证用户，同时也提供了一些便利的方法用于访问基本的 authorization 头信息。

## Authorization

authorization 头信息是一个客户端发送 credentials 很好的地方。

```
Authorization: xxxxxxxxxx
```

你能通过 `req.auth.header` 方法访问 authorization 头信息。两种基本的模式是 basic 和 bearer。

### Basic

Basic authorization 包含用户名和密码被一个冒号连接在一起，并以base64算法进行编码得到的字符串。

```
Authorization: Basic QWxhZGRpbjpPcGVuU2VzYW1l
```

这是一个 header 的例子，你能在 [wikipedia](https://en.wikipedia.org/wiki/Basic_access_authentication). 阅读更多关于 basic auth 的内容。

下面展示如何使用 `req.auth` 访问这个 header。

```swift
guard let credentials = req.auth.header?.basic else {
    throw Abort.badRequest
}
```

basic 头信息返回一个 `APIKey` credential。

```
class APIKey: Credentials {
	let id: String
	let secret: String
}
```

### Bearer

另外的一种基本方式是 bearer，它包含一个唯一的 API key。

```
Authorization: Bearer apikey123
```

它的访问类似 basic 头信息的访问，返回一个 `AccessToken`。

```
class AccessToken: Credentials {
	let string: String
}
```

### Raw

To access the raw authorization header, use `req.auth.header?.header`.
要访问原始的授权头信息，可以使用 `req.auth.header?.header`。

## 令牌 （Credentials）

Basic 和 Bearer 认证都会放回实现了 `Credentials` 的东西。你也能通过实现 `Credentials` 协议或者手动创建 `APIKey`, `AccessToken`, `Identifier` 去创建你自己的认证 `Credentials`。

```swift
let key = AccessToken(string: "apikey123")
```

### Input

你能够从表单或者 JSON 数据中创建 credential。

```swift
guard
	let username = req.data["username"]?.string,
	let password = req.data["password"]?.string
else {
	throw Abort.badRequest
}

let key = APIKey(id: username, secret: password)
```

## Login

一旦你有一些实现了 Credentials 协议的对象，你能够尝试去登录用户。

```swift
try req.auth.login(credentials)
```

如果这个调用成功了，这个用户就登录了并且已经开始了 session 会话。这将一直登录着，知道他们的的 cookie 失效。

### Authenticate

登录会调用你提供的 `AuthMiddleware` 中间件中的 `Auth.User` model 的 `authenticate` 方法。确保你已经对你想要使用的所有 credential 都添加了支持。

> Note: If you used a custom Realm, it will be called instead.

### Identifier

Another important credential type is the `Identifier` type. This is used by Vapor when fetching the `User` object from the `vapor-auth` cookie. It is also a convenient way to log a user in manually.

```swift
static func authenticate(credentials: Credentials) throws -> Auth.User {
	switch credentials {
	...
	case let id as Identifier:
		guard let user = try User.find(id.id) else {
			throw Abort.custom(status: .badRequest, message: "Invalid identifier.")
		}

		return user
	...
	}
}
```

为 `Credentials` 添加 `Identifier` case 是十分简单的，只是通过 identifier 查找用户。

```swift
let id = Identifier(id: 42)
try req.auth.login(id)
```

现在你能够手动使用用户的 identifier 登录。

### 临时的 （Ephemeral）

如果你只是想在一次请求中登录用户，不持久化它。

```swift
req.auth.login(credentials, persist: false)
```

> 注意： 支持 `Identifier` credentials,持久认证（persisted authentication）是正常运行所必需的。

## User

默认情况下，`request.auth.user()` 返回已经授权的 `Auth.User`。它需要转换成你内部的 `User` 类型去使用。

在 `Request` 添加便利方法是简化这个的一个很好的方式。

```swift
extension Request {
    func user() throws -> User {
        guard let user = try auth.user() as? User else {
            throw Abort.custom(status: .badRequest, message: "Invalid user type.")
        }

        return user
    }
}
```

Now you can access your `User` type with `try req.user()`.
