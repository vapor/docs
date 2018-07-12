# Routing Overview

Routing ([vapor/routing](https://github.com/vapor/routing)) is a small framework for routing things like HTTP requests. It lets you register and lookup routes in a router using nested, dynamic path components.

!!! tip
    If you use Vapor, most of Routing's APIs will be wrapped by more convenient methods. See [Vapor → Routing] for more information.

This guide will show you how to register a static route and a dynamic route and how to use [`Parameter`](https://api.vapor.codes/routing/latest/Routing/Protocols/Parameter.html)s.

## Register

The first step to routing is to register some routes. Let's take a look at how to do that with a simple router&mdash;a `TrieRouter<Double>` which holds numbers. Usually you would store something like HTTP responders, but we'll keep things simple for this example.

```swift
// Create a router that stores Doubles
let router = TrieRouter(Double.self)

// Register some routes and values to the router
router.register(route: Route(path: ["funny", "meaning_of_universe"], output: 42))
router.register(route: Route(path: ["funny", "leet"], output: 1337))
router.register(route: Route(path: ["math", "pi"], output: 3.14))

// Create empty Parameters to hold dynamic params (none yet)
var params = Parameters()

// Test fetching some routes
print(router.route(path: ["fun", "meaning_of_universe"], parameters: &params)) // 42
print(router.route(path: ["foo"], parameters: &params)) // nil
```

Here we are using [`register(...)`](https://api.vapor.codes/routing/latest/Routing/Classes/TrieRouter.html#/s:7Routing10TrieRouterC8registeryAA5RouteCyxG5route_tF) to register routes to our router, then later [`route(...)`](https://api.vapor.codes/routing/latest/Routing/Classes/TrieRouter.html#/s:7Routing10TrieRouterC5routexSgSayqd__G4path_AA10ParametersVz10parameterstAA17RoutableComponentRd__lF) to fetch them. The [`TrieRouter`](https://api.vapor.codes/routing/latest/Routing/Classes/TrieRouter.html) uses a trie (digital tree) internally to make finding value in the router fast.

## Parameter

Let's take a look at registering some dynamic path components. These are parts of the path that are variable and whose value should be collected for later use. You will often see this used for situations like show a webpage for a user:

```
/users/:user_id
```

Here is how you would implement that with `TrieRouter`. For this example, we will ignore the route output.

```swift
// Create a route for /users/:user_id
let user = Route(path: [.constant("users"), .parameter("user_id")], output: ...)

// Create a router and register our route
let router = TrieRouter(...)
router.register(route: user)

// Create empty Parameters to hold dynamic values
var params = Parameters()

// Route the path /users/42
_ = router.route(path: ["users", "42"], parameters: &params)

// The params contains our dynamic value!
print(params) // ["user_id": "42"]
```

Note that the String used for `.parameter(...)` will be the key to fetch the value from `Parameters`.

## API Docs

Check out the [API docs](https://api.vapor.codes/routing/latest/Routing/index.html) for more in-depth information about all of the available parameters and methods.
