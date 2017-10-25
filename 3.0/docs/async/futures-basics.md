# Future basics

Futures are used throughout Vapor, so it is useful to know some of the available helpers.

## Adding awaiters to all results

If you need to handle the results of an operation regardless of success or failure, you can do so by calling the `.addAwaiter` function on a future.

The awaiter shall be called on completion with a `Result<Expectation>`. This is an enum with either the `Expectation` or an `Error` contained within.

```swift
let future = Future("Hello world")

future.addAwaiter { result in
  switch result {
  case .expectation(let string):
    print(string)
  case .error(let error):
    print("Error: \(error)")
  }
}
```

## Flat-Mapping results

Nested async callbacks can be a pain to unwind. An example of a painfully complex "callback hell" scenario is demonstrated below:

```swift
app.get("friends") { request in
	let session = try request.getSessionCookie() as UserSession

	let promise = Promise<View>()

	// Fetch the user
	try session.user.resolve().then { user in
		// Returns all the user's friends
		try user.friends.resolve().then { friends in
			return try view.make("friends", context: friends, for: request).then {	renderedView in
				promise.complete(renderedView)
			}.catch(promise.fail)
		}.catch(promise.fail)
	}.catch(promise.fail)

	return promise.future
}
```

Vapor 3 offers a `flatMap` solution here that will help keep the code readable and maintainable.

```swift
app.get("friends") { request in
	let session = try request.getSessionCookie() as UserSession

	// Fetch the user
	return try session.user.resolve().flatten { user in
		// Returns all the user's friends
		return try user.friends.resolve()
	}.map { friends in
		// Flatten replaced this future with
		return try view.make("friends", context: friends, for: request)
	}
}
```

## Combining multiple futures

If you're expecting the same type of result from multiple sources you can group them using the `flatten` function.

```swift
var futures = [Future<String>]()
futures.append(Future("Hello"))
futures.append(Future("World"))
futures.append(Future("Foo"))
futures.append(Future("Bar"))

let futureResults = futures.flatten() // Future<[String]>
```
