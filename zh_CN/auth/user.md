---
currentMenu: auth-user
---

# Auth

> 翻译：[@孟祥月_iOS](http://weibo.com/u/1750643861)

认证和授权被集中在 `Auth.User` 协议中。认证类似问：“你是谁？”，然后授权类似问：“他们能够做啥？”。Vapor 包含一个可扩展的认证系统，你能够使用它作为基础构建更加精细的授权系统

> 注释：可以在 GitHub 上找到一个 [auth-example](https://github.com/vapor/auth-example)。

## User Protocol

任何类型都能实现 `Auth.User` 协议，但它们通常添加到 Fluent `Model` 中。

```swift
import Vapor
import Auth

final class User: Model {
    var id: Node?
    var name: String

	...
}

extension User: Auth.User {
    static func authenticate(credentials: Credentials) throws -> Auth.User {

    }

    static func register(credentials: Credentials) throws -> Auth.User {

    }
}
```

这是一个例子：`User` 类实现了 `Auth.User` 协议及其方法。注意我们的类的名字和协议名字是相同的。这就是为什么我们使用 `Auth.` 前缀用于把 `Auth` 协议中的 `User` 从我们的 `User` 类中区分出来。

### Authenticate

当一系列的 credentials 被传入到静态方法 `authenticate` 中，并且匹配的用户被返回后，这个用户就是被认证的。

#### Credentials

```swift
protocol Credentials { }
```

credentials 协议是一个空协议，所有的类型都可以实现。这个给了你的认真 model 很大的灵活性，但也要求您正确处理不受支持的 credentials 的情况。

#### Access Token

Vapor 中包含的最简单的 credential 类型是 `AccessToken`。它包含一个基于 token 的 `String`，用来认证该用户。

让我看看如何支持 access token 类型。

```swift
static func authenticate(credentials: Credentials) throws -> Auth.User {
	switch credentials {
	case let accessToken as AccessToken:
		guard let user = try User.query().filter("access_token", accessToken.string).first() else {
			throw Abort.custom(status: .forbidden, message: "Invalid access token.")
		}

		return user
	default:
		let type = type(of: credentials)
		throw Abort.custom(status: .forbidden, message: "Unsupported credential type: \(type).")
	}
}
```

第一步是将 credentials 转换为我们想要的类型--在这个例子中是 `AccessToken`。如果没有 access token，我们通知客户端，该 credentials 是非法的。

一旦我们有 access token，我们将会使用它去查找匹配 access token 的 `User` model 的实体。这个假设 `users` table 或者 collection 存储了 access tokens。您可以选择将它们存储在其他地方。

一旦我们发现了与提供的 access token 相关的 user，我们只是简单的返回它。

#### Identifier

Vapor 内部使用 `Identifier` credential 类型从 session 中查找用户。你能在 [Request](request.md) 部分阅读更多内容。

### Register

Similar to the authenticate method, the register method takes credentials. But instead of fetching the user from the data store, it provides a convenient way to create the user. You are not required to register your users through this method.   
与认证类似，register 方法获取 credentials。不是从数据存储获取用户，它提供了一种方便的方式来创建用户。您不需要通过此方法注册您的用户。

## Example

这是一个支持多种 credentials 的 User 的例子：

```swift
extension User: Auth.User {
    static func authenticate(credentials: Credentials) throws -> Auth.User {
        let user: User?

        switch credentials {
        case let id as Identifier:
            user = try User.find(id.id)
        case let accessToken as AccessToken:
            user = try User.query().filter("access_token", accessToken.string).first()
        case let apiKey as APIKey:
            user = try User.query().filter("email", apiKey.id).filter("password", apiKey.secret).first()
        default:
            throw Abort.custom(status: .badRequest, message: "Invalid credentials.")
        }

        guard let u = user else {
            throw Abort.custom(status: .badRequest, message: "User not found.")
        }

        return u
    }

    static func register(credentials: Credentials) throws -> Auth.User {
		...
    }
}
```

> 注意：不要尝试存储密码。如果必须存储，hash 并且加盐后存储。
