---
currentMenu: routing-collection
---

# Route Collections

Route collections allow multiple routes and route groups to be organized in different files or modules.

## Example

Here is an example of a route collection for the `v1` portion of an API.

```swift
import Vapor
import HTTP
import Routing

class V1Collection: RouteCollection {
    typealias Wrapped = HTTP.Responder
    func build<B: RouteBuilder>(_ builder: B) where B.Value == Wrapped {
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

This class could be place in any file, and we could add it to our droplet or even another route group.

```swift
let v1 = V1Collection()
drop.collection(v1)
```

The `Droplet` will then be passed to the `build(_:)` method of your route collection and have the various routes added to it.

### Breakdown

For those that are curious, let's break down the route collection line by line to better understand what is going on.

```swift
typealias Wrapped = HTTP.Responder
```

This limits our route collection to adding HTTP responders. While the underlying router is capable of routing any type, Vapor routes HTTP responders exclusively. If we want to use this route collection with Vapor, it's wrapped type needs to match.

```swift
func build<B: RouteBuilder>(_ builder: B) where B.Value == Wrapped {
```

This method accepts a route builder and also verifies that the route builder accepts `Wrapped` or, as defined in the last line, `HTTP.Responder`s. Vapor's `Droplet` and any route [group](group.md) created with Vapor are `RouteBuilder`s that accept HTTP responders.

```swift
let v1 = builder.grouped("v1")
```

From there you can create routes with the `builder` as usual. The `builder: B` will work exactly like a `Droplet` or route [group](group.md). Any methods that work there will work on this builder.


## Empty Initializable

You can even add `EmptyInitializable` to your route collection if it has an empty `init` method. This will allow you to add the route collection via its type name.

```swift
class V1Collection: RouteCollection, EmptyInitializable {
	init() { }
	...
```

Now we can add the collection without initializing it.

```swift
drop.collection(V1Collection.self)
```
