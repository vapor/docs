# Route Collections

Route collections allow multiple routes and route groups to be organized in different files or modules.

## Example

Here is an example of a route collection for the `v1` portion of an API.

```swift
import Vapor
import HTTP
import Routing

class V1Collection: RouteCollection {
    func build(_ builder: RouteBuilder) {
        let v1 = builder.grouped("v1")
        let users = v1.grouped("users")
        let articles = v1.grouped("articles")

        users.get { request in
            return "Requested all users."
        }

        articles.get(Article.init) { request, article in
            return "Requested \(article.name)"
        }
    }
}
```

This class could be placed in any file, and we could add it to our droplet or even another route group.

```swift
let v1 = V1Collection()
drop.collection(v1)
```

The `Droplet` will then be passed to the `build(_:)` method of your route collection and have the various routes added to it.


## Empty Initializable

You can add `EmptyInitializable` to your route collection if it has an empty `init` method. This will allow you to add the route collection via its type name.

```swift
class V1Collection: RouteCollection, EmptyInitializable {
	init() { }
	...
```

Now we can add the collection without initializing it.

```swift
drop.collection(V1Collection.self)
```
