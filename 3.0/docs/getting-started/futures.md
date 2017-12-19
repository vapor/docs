# Futures

You may have noticed some APIs in Vapor expect or return a `Future<T>` type.
If this is your first time hearing about futures, they might seem a little confusing at first.
But don't worry, Vapor makes them easy to use.

Promises and Futures are two strongly related types. Every promise has a future.
A promise is a write-only entity that has the ability to complete (or fail) it's Future counterpart.

Futures are a read-only entity that can have a successful or error case. Successful cases are called the "Expectation".

Futures can be used to register callbacks to, which will always executed in the order of registration. Promises can only be completed once. If a promise is completed more than once the input will be *ignored*.

## Basics

Creating a promise is when the result is returned in the future at an unknown time.
For the sake of demonstration, however, the promise will be completed at a predefined point in time and execution.

Within the `.do` block you may not throw an error or return a result.

```swift
let promise = Promise<String>()
let future = promise.future // Future<String>

future.do { string in
  print(string)
}

promise.complete("Hello")
```

The above code prints "Hello" in the console.

## Errors

When running the above code, you may have noticed a warning pop up. This is because the `.do` block only handles successful completions. If we were to replace the completion with the following code the `.do` block would never get run:

```swift
struct MyError: Error {}

promise.fail(MyError())
```

Instead, a `.catch` block will be triggered.

```swift
future.do { string in
  print(string)
}.catch { error in
  print("Error '\(error)' occurred")
}
```

In this scenario the test "Error 'MyError' occurred" will appear.

Within the `.catch` block you may not throw an error or return a result.

## Basic Transformations

Transformations are one of the more critical parts of Vapor 3's future system. They assist in reducing the complexity of futures and keep code isolated and readable. You can use the `.map` function to transform the future expectation to another future of the same or a different type. You need to explicitly state which type will be returned in the mapping closure.

The mapping closure(s) will *only* be executed if an expectation has been received in the previous step. If at any point a transformation function throws an error, execution stops there and the `.catch` block will be executed.

If the promise that was mapped failed to begin with, the `.catch` block will also be executed _without_ triggering *any* mapping closures.

```swift
let promise = Promise<Int>()

promise.future.do { int in
  print(int)
}.map(to: Int.self) { int in
  return int + 4
}.map(to: String.self) { int in
  return int.description
}.do { string in
  print(string)
}.catch { error in
  print("Error '\(error)' occurred")
}

promise.complete(3)
```

The above code will print the inputted integer. Then map the input to `(integer + 4) == 7`.
Then the textual representation of the integer is returned as a `String` which will be printed.

This results in the following console output:

```sh
3
7
```

## Recursive futures

In the above `map` function we returned a new result synchronously. In some situations, however, you'll need to dispatch another asynchronous call based on the result of a previous call.

First, let's see how this would work out using `map` by exaggerating synchronous code as if it were an asynchronous call.

```swift
let promise = Promise<Int>()

promise.map(to: Future<Int>.self) { int in
  return Future(int + 4)
}.map(to: Future<Future<String>>.self) { futureInt in
  return futureInt.map(to: Future<String.self>) { int in
    return Future(int.description)
  }
}.do { doubleFutureString in // Future<Future<String>>
  doubleFutureString.do { futureString in // Future<String>
    futureString.do { string in
      print(string)
    }.catch { error in
      print("Error '\(error)' occurred")
    }
  }.catch { error in
    print("Error '\(error)' occurred")
  }
}.catch { error in
  print("Error '\(error)' occurred")
}

promise.complete(3)
```

To flatten this asynchronous recursion, instead, we recommend using `flatMap`.
The type supplied in the `to:` argument is implied to be wrapped in a `Future<>`.

```swift
let promise = Promise<Int>()

promise.flatMap(to: Int.self) { int in
  return Future<Int>(int + 4)
}.flatMap(to: String.self) { int in
  return Future(int.description)
}.do { string in
  print(string)
}.catch { error in
  print("Error '\(error)' occurred")
}

promise.complete(3)
```

## Always

Sometimes you want to always execute a function as part of the cleanup phase.
You can use the `.always` block to execute a block of code after the future has been successfully executes (and mapped if applicable) or when an error occurred. Please do consider that finally also will be executed in the order in which it has been registered, like all other closures.

```swift
var i = 0

let promise = Promise<Int>()
let future = promise.future // Future<Int>

future.do { int in
  i += int * 3
}.do { int in
  i += (int - 1)
}.catch {
  i = -1
}.finally {
  print(i)
  i = 0
}
```

At the end of the above function, `i` will *always* be 0. If the promise is completed with the successful result `i`, the number "11" will be printed. On error, "-1" will be printed.

## Signals

Signals, or `Future<Void>` is a Future that can contain either an Error or Void (the Expectation). `Future<Void>` is often used to indicate the successful or unsuccessful completion of a task.
