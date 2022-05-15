# Validation API

Vapor 的 **Validation API** 可帮助你在使用 [Content](content.md) API 解码数据之前，对传入的请求进行验证。

## 介绍 

Vapor 对 Swift 的类型安全的`可编码`协议进行了深度集成，这意味着与动态类型的语言相比，你无需担心数据验证。但是，出于某些原因，你可能想选择使用 **Validation API** 进行显式验证。


### 语义可读错误

如果取得的数据无效，使用 [Content](content.md) API 对其解码将产生错误。但是，这些错误消息有时可能缺乏可读性。例如，采用以下字符串支持的枚举：

```swift
enum Color: String, Codable {
    case red, blue, green
}
```

如果用户尝试将字符串“purple”传递给“Color”类型的属性，则将收到类似于以下内容的错误：

```
Cannot initialize Color from invalid String value purple for key favoriteColor
```

尽管此错误在技术上是正确的，并且可以成功地保护端点免受无效值的影响，但它可以更好地通知用户该错误以及可用的选项。通过使用 **Validation API**，你可以生成类似以下的错误：

```
favoriteColor is not red, blue, or green
```

此外，一旦遇到第一个错误，`Codable` 将停止尝试解码。这意味着即使请求中有许多无效属性，用户也只会看到第一个错误。 **Validation API** 将在单个请求中抛出所有的验证失败信息。

### 特殊验证

`Codable` 可以很好地处理类型验证，但是有时候你还想要更多的验证方式。例如，验证字符串的内容或验证整数的大小。**Validation API** 具有此类验证器，可帮助验证电子邮件、字符集、整数范围等数据。

## 验证

为了验证请求，你需要生成一个 `Validations` 集合。最常见的做法是使现有类型继承 **Validatable**。

让我们看一下如何向这个简单的 `POST/users` 请求添加验证。本指南假定你已经熟悉 [Content](content.md) API。


```swift
enum Color: String, Codable {
    case red, blue, green
}

struct CreateUser: Content {
    var name: String
    var username: String
    var age: Int
    var email: String
    var favoriteColor: Color?
}

app.post("users") { req -> CreateUser in
    let user = try req.content.decode(CreateUser.self)
    // Do something with user.
    return user
}
```

### 添加验证

第一步是在你要解码的类型（在本例中为 CreateUser）继承 **Validatable** 协议并实现 `validations` 静态方法，可在 `extension` 中完成。

```swift
extension CreateUser: Validatable {
    static func validations(_ validations: inout Validations) {
        // Validations go here.
    }
}
```

验证`CreateUser`后，将调用静态方法 `validations（_ :)`。你要执行的所有验证都应添加到 **Validations** 集合中。让我们添加一个简单的验证，以验证用户的电子邮件是否有效。

```swift
validations.add("email", as: String.self, is: .email)
```

第一个参数是参数值的预期键，在本例中为`email`。这应与正在验证的类型上的属性名称匹配。第二个参数`as`是预期的类型，在这种情况下为`String`。该类型通常与属性的类型匹配。最后，可以在第三个参数`is`之后添加一个或多个验证器。在这种情况下，我们添加一个验证器，以检查该值是否为电子邮件地址。


### 验证请求的 `Content`

当你的数据类型继承了 **Validatable**，就可以使用 `validate(content:)` 静态方法来验证请求的 `content`。在路由处理程序中 `req.content.decode(CreateUser.self)` 之前添加以下行：

```swift
try CreateUser.validate(content: req)
```

现在，尝试发送以下包含无效电子邮件的请求：

```http
POST /users HTTP/1.1
Content-Length: 67
Content-Type: application/json

{
    "age": 4,
    "email": "foo",
    "favoriteColor": "green",
    "name": "Foo",
    "username": "foo"
}
```

你应该能看到返回以下错误：

```
email is not a valid email address
```

### 验证请求的 `Query`

当你的数据类型继承了 **Validatable**，就可以使用 `validate(query:)` 静态方法来验证请求的 `query`。在路由处理程序中添加以下行：

```swift
try CreateUser.validate(query: req)
req.query.decode(CreateUser.self)
```

现在，尝试发送一下包含错误的 email 在 query 的请求。

```http
GET /users?age=4&email=foo&favoriteColor=green&name=Foo&username=foo HTTP/1.1

```

你将会看到下面的错误：

```
email is not a valid email address
```
### 整数验证

现在让我们尝试添加一个针对整数年龄的验证：

```swift
validations.add("age", as: Int.self, is: .range(13...))
```

年龄验证要求年龄大于或等于`13`。如果你尝试发送一个和上面相同的请求，现在应该会看到一个新错误：

```
age is less than minimum of 13, email is not a valid email address
```

### 字符串验证

接下来，让我们添加对“名称”和“用户名”的验证。

```swift
validations.add("name", as: String.self, is: !.empty)
validations.add("username", as: String.self, is: .count(3...) && .alphanumeric)
```


名称验证使用 `!` 运算符将 `.empty` 验证反转。这要求该字符串不为空。
用户名验证使用`&&`组合了两个验证器。这将要求该字符串的长度至少为3个字符，并且使用 && 来包含字母数字字符。


### 枚举验证

最后，让我们看一下更高级的验证，以检查提供的`favoriteColor`是否有效：

```swift
validations.add("favoriteColor", as: String.self,is: .in("red", "blue","green"),required: false)

```

由于无法从无效值中解码“颜色”，因此此验证将“字符串”用作基本类型。它使用 .in 验证器来验证该值是有效的选项：红色、蓝色或绿色。由于该值是可选的，因此将`required`设置为 false 表示如果请求数据中缺少此字段，则验证不会失败。

请注意，如果缺少此字段，则收藏夹颜色验证将通过，但如果提供 `null`，则不会通过。 如果要支持`null`，请将验证类型更改为`String?`，并使用 `.nil ||`。

```swift
validations.add("favoriteColor", as: String?.self,is: .nil || .in("red", "blue", "green"),required: false)
```


## 验证器

以下是当前支持的验证器的列表，并简要说明了它们的作用：

|验证方式|描述|
|:--|:--|
|`.ascii`|仅包含ASCII字符|
|`.alphanumeric`|仅包含字母数字字符|
|`.characterSet(_:)`|仅包含提供的 `CharacterSet` 中的字符|
|`.count(_:)`|在提供范围内的集合计数|
|`.email`|包含有效的电子邮件|
|`.empty`|集合为空|
|`.in(_:)`|值在提供的“集合”中|
|`.nil`|值为`null`|
|`.range(_:)`|值在提供的范围内|
|`.url`|包含有效的URL|

验证器也可以使用运算符组合起来以构建复杂的验证：

|操作符|位置|描述|
|:--|:--|:--|
|`!`|前面|反转验证器，要求相反|
|`&&`|中间|组合两个验证器，需要同时满足|
|`||`|中间|组合两个验证器，至少满足一个|