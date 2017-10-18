# Introduction into Promises and Futures

When working with asynchronous APIs, one of the problems you'll face is not knowing when a variable is set.

When querying a database synchronously, the thread is blocked until a result has been received. At which point the result will be returned to you and the thread continues from where you left off querying the database.

```swift
let user = try database.fetchUser(named: "Admin")

print(user.username)
```

In the asynchronous world, you won't receive a result immediately. Instead, you'll receive a result in a callback.

```swift
// Callback `found` will receive the user. If an error occurred, the `onError` callback will be called instead.
try database.fetchUser(named: "Admin", found: { user in
  print(user.username)
}, onError: { error in
  print(error)
})
```

You can imagine code becoming complex. Difficult to read and comprehend.

Promises and futures are two types that this library introduces to solve this.

## Creating a promise

Promises are important if you're implementing a function that returns a result in the future, such as the database shown above.

Promises need to be created without a result. They can then be completed with the expectation or an error at any point.

You can extract a `future` from the `promise` that you can hand to the API consumer.

```swift
// the example `fetchUser` implementation
func fetchUser(named name: String) -> Future<User> {
	// Creates a promise that can be fulfilled in the future
	let promise = Promise<User>()

	do {
    // TODO: Run a query asynchronously, looking for the user

		// Initialize the user using the datbase result
		// This can throw an error if the result is empty or invalid
		let user = try User(decodingFrom: databaseResult)

		// If initialization is successful, complete the promise.
		//
		// Completing the promise will notify the promise's associated future with this user
		promise.complete(user)
	} catch {
		// If initialization is successful, fail the promise.
		//
		// Failing the promise will notify the promise's associated future with an error
		promise.fail(error)
	}

	// After spawning the asynchronous operation, return the promise's associated future
	//
	// The future can then be used by the API consumer
	return promise.future
}
```

## On future completion

When a promise completes, you can chain the result/error into a closure:

```swift
// The future provided by the above function will be used
let future: Future<User> = fetchUser(named: "Admin")

// `.then`'s closure will be executed on success
future.then { user in
  print(user.username)
// `.catch` will catch any error on failure
}.catch { error in
  print(error)
}
```

## Catching specific errors

Sometimes you only care for specific errors, for example, for logging.

```swift
// The future provided by the above function will be used
let future: Future<User> = fetchUser(named: "Admin")

// `.then`'s closure will be executed on success
future.then { user in
  print(user.username)
// This `.catch` will only catch `DatabaseError`s
}.catch(DatabaseError.self) { databaseError in
	print(databaseError)
// `.catch` will catch any error on failure, including `DatabaseError` types
}.catch { error in
  print(error)
}
```

## Mapping results

Futures can be mapped to different results asynchronously.

```swift
// The future provided by the above function will be used
let future: Future<User> = fetchUser(named: "Admin")

// Maps the user to it's username
let futureUsername: Future<String> = future.map { user in
	return user.username
}

// Mapped futures can be mapped and chained, too
futureUsername.then { username in
	print(username)
}
```

## Futures without promise

In some scenarios you're required to return a `Future` where a `Promise` isn't necessary as you already have the result.

In these scenarios you can initialize a future with the already completed result.

```swift
// Already completed on initialization
let future = Future("Hello world!")

future.then { string in
  print(string)
}
```

## Synchronous APIs

Sometimes, an API needs to be used synchronously in a synchronous envinronment.

Rather than using a synchronous API with all edge cases involved, we recommend using the `try future.blockingAwait()` function.

```swift
// The future provided by the above function will be used
let future: Future<User> = fetchUser(named: "Admin")

// This will either receive the user if the promise was completed or throw an error if the promise was failed.
let user: User = try future.blockingAwait()
```

This will wait for a result indefinitely, blocking the thread.

If you expect a result with a specified duration, say, 30 seconds:

```swift
// This will also throw an error if the deadline wasn't met
let user = try future.blocked(timeout: .seconds(30))
```
