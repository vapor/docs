# Using Async

Async is a library revolving around two main concepts:

- [Promises and Futures](futures.md)
- [(Reactive) Streams](streams.md)
- [EventLoops](eventloop.md)

Together they form the foundation of Vapor 3's data flow.
Asynchronous programming, reactiveness and non-blocking I/O make up the foundation of Vapor 3's internals.

### What is asynchronous programming?

Normally when requesting information in your code your code returns the results synchronously.
Take a chat, for example. If you request the next chat message from your friend you'll receive the message "normally".

```swift
let message: ChatMessage = try chat.getNextMessage()
```

A normal internet connection has many factors that can and will increase the duration until this function completes.
Sometimes you may get the next chat message within 10 ms, other times the function returns after 10 seconds.

The unpredictability of the outside world can severely impact performance and stability of an application.
Whilst waiting for the information to arrive the computer "blocks" the thread until the information is ready.
This form of programming is called "synchronous" programming.

To work around this issue, more performant applications are written in a "non-blocking" fashion.
This means receiving results when they're available and continuing doing other work in the timespan in between.

The pattern we employ to communicate these changes is the `Future` pattern, a form of "asynchronous" programming.

### How does async impact my application?

One way this impacts your application is by providing an increased resistance to attacks on your application.
At the same time, your application's performance improves.

Besides the technical difference there's a practical difference.
In synchronous programming you're developing an application using variables that are guaranteed to exist.
In asynchronous programming, you're setting up code that will handle similarly but based on events.

One such event might be "once I've received the next chat message" or "When receiving the next chat message failed".

## Using async with Vapor

This package is included with Vapor by default, just add:

```swift
import Async
```

## Using async without Vapor

Async is a powerful library for any Swift project. To include it in your package, add the following to your `Package.swift` file.

```swift
// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "Project",
    dependencies: [
        ...
        .package(url: "https://github.com/vapor/async.git", from: "1.0.0"),
    ],
    targets: [
      .target(name: "Project", dependencies: ["Async", ... ])
    ]
)
```

!!! warning
    The `1.0.0` tag is not available during the pre-release phase. [Check the latest tag &rarr;](https://github.com/vapor/async/releases)

Use `import Async` to access Async's APIs.

To learn the basics, check out [Async &rarr; Futures](futures.md)

<!-- TODO: Update async dependency pointer on release -->
