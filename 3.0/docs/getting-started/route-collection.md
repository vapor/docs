# Route Collection

`RouteCollection` is a protocol that you can conform your controllers to.

They require the implementation of the `register` function which can then register the routes to a router.

```swift
class LoginController {
  init() {}

  func register(to router: Router) {
    ...
  }
}
```
