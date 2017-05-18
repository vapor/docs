---
currentMenu: routing-collection
---

# Route Collections

> 翻译：[@孟祥月_iOS](http://weibo.com/u/1750643861)

Route collection 允许多个路由和路由组被组织在不同的文件或者模块中。

## Example

这里是一个API的`v1`部分的 route collection 的示例。


```swift
import Vapor
import HTTP
import Routing

class V1Collection: RouteCollection {
    typealias Wrapped = HTTP.Responder
    func build<B: RouteBuilder where B.Value == Wrapped>(_ builder: B) {
        let v1 = builder.grouped("v1")
        let users = v1.grouped("users")
        let articles = v1.grouped("articles")

        users.get { request in
            return "Requested all users."
        }

        articles.get(Article.self) { request, article in
            return "Requested \(article.name)"
        }
    }
}
```

这个类可以放在任何文件中，我们可以添加它到我们的 droplet中，或者添加到其他的路由组中。

```swift
let v1 = V1Collection()
drop.collection(v1)
```

然后 `Droplet` 将会被传入到你的 route collection 的 `build(_:)` 方法中，并且添加各种路由。

### 分解 （Breakdown）

对于那些对这些比较好奇的人，让我们分解一行一行的分解 route collection，更好的了解一下怎么执行的。

```swift
typealias Wrapped = HTTP.Responder
```

这个限制我们 route collection 需要添加 HTTP responser。虽然底层的路由器能够路由各种类型，但是 Vapor 专门路由 HTTP responser。如果你想使 Vapor 的 route collection，这个 warpped 类型必须匹配。

```swift
func build<B: RouteBuilder where B.Value == Wrapped>(_ builder: B) {
```

这个方法接受一个 router builder，并且校验 router builder 是否与 `Wrapped` 或者 `HTTP.Responder` 匹配。Vapor的`Droplet`和用 Vapor 创建的任何路由 [组](group.md) 都是`RouteBuilder`，接受HTTP响应

```swift
let v1 = builder.grouped("v1")
```

从这里开始，你能够像平时一样使用 `builder` 创建 route 了。 `builder: B` 能够像 `Droplet` 或者 route [group](group.md) 一样工作。任何在这里运行的方法豆浆运行在这个 builder 上。


## Empty Initializable

如果你有空的初始化方法，你可以添加 `EmptyInitializable` 到你的 route collection。这个允许你通过它的类型名添加该 route colleciton。

```swift
class V1Collection: RouteCollection, EmptyInitializable {
	init() { }
	...
```

Now we can add the collection without initializing it.

```swift
drop.collection(V1Collection.self)
```
