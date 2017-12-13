# Futures

You may have noticed some APIs in Vapor expect or return a `Future<T>` type.
If this is your first time hearing about futures, they might seem a little confusing at first.
But don't worry, Vapor makes them easy to use.

## Callbacks

Futures are a way of representing an object that you don't have yet. You have probably seen
APIs that use callbacks before (especially if you have developed iOS apps). Futures are just a
way to make APIs with callbacks more user-friendly.

This is a what a common callback API looks like.

```swift
api.getUsers(onCompletion: { users, error in
    // check if there's an error
    // do something with the users
})
```

With futures, we don't have to supply a callback. We get back instead `Future<[User]>`.

```swift
let users = api.getUsers()
print(users) // Future<[User]>
```

!!! info
    Futures use fewer system resources than synchronous APIs. This is part of
    what makes Vapor so fast!

## Chaining

What's great about futures is they allow us to chain multiple actions together without nesting callbacks.

Let's take a look at an example of this with callbacks.

```swift
api.doThingOne(onCompletion: { one, error in
    // check if there's an error
    api.doThingTwo(onCompletion: { two, error in
        // check if there's an error
        api.doThingThree(onCompletion: { three, error in
            // check if there's an error
            api.doThingFour(onCompletion: { four, error in
                // check if there's an error
            })
        })
    })
})
```

Futures prevent nesting and greatly simplify error checking.

```swift
let four = api.doThingOne().flatMap(ResultTwo.self) {
    return api.doThingTwo()
}.flatMap(ResultThree.self) {
    return api.doThingThree()
}.flatMap(ResultFour.self) {
    return api.doThingFour()
}

print(four) // The future result of `doThingFour()`
```

Notice that we didn't need to check for errors when we chained with futures. When we attempt to resolve `four`,
we can catch errors thrown anywhere in the chain.

```swift
four.do { four in
    print(four) // the result
}.catch { err in
    print(err) // error thrown from thing one, two, three, or four
}
```

Learn more about Vapor's async architecture in [Concepts &rarr; Async](../concepts/async.md).
Or take a deeper look at Futures and Promises in [Async &rarr; Getting Started](../async/futures.md).
