# Route Collection

`RouteCollection` is a protocol that you can conform your controllers to.

They require the implementation of the `boot` function which can register routes to a router.

```swift
class LoginController: RouteCollection {
  init() {}

  func boot(router: Router) {
    ...
  }
}
```
