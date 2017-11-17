# Async

Async APIs are one of the most important aspects of Vapor 3. You have likely noticed that they are
the biggest change to the API from previous versions. To learn more about how to use the new async
APIs check out the [Async &rarr; Getting Started](../async/getting-started.md) section. This document
aims to explain _why_ Vapor 3 moved to async APIs and _how_ it has led to huge performance gains.

## Differences

Let's first make sure we understand the different between a "sync" and "async" API. 

```swift
// sync
let users = try api.getUsers()
```

Sync APIs return values immediately. 

```swift
// async
try api.getUsers(onCompletion: { users, error in

})
```

Async APIs return their value at some point in the future. There are many different ways to implement
async APIs (such as [futures](../getting-started/futures.md)), but we will use callbacks here to make it obvious.

## Concurrency

It's fairly obvious from the above snippet that sync APIs are more concise. So why would anyone use an async API?
To understand why, you must first understand how concurrency works with these two API types. 

### Sync (Blocking)

In Swift, most APIs are synchronous. For example, when you convert a string to uppercase.

```swift
let hello = "Hello".uppercased()
```

There is no problem with this API being synchronous because at no point in converting "Hello" to uppercase is
the computer ever _waiting_. Waiting, also called "blocking", is an important concept. Most simple functions, 
like `.uppercased()` never wait&mdash;they are busy doing the requested work (i.e., capitalizing letters) the entire time.
However, some functions do wait. The classic example of this is a function that makes a network request.

```swift
/// sync + blocking
let res = try HTTPClient.getSync("http://google.com")
```

In the above example, the `.getSync` function must block. After it sends the request to `google.com`, it must wait for
their server to generate a response. While this function is waiting, it can't do anything. In other words, the CPU 
is idle. If you're trying to optimize your application, you'd quickly notice that letting your (expensive) CPU sit 
idle is not a great idea.

### Async (Non-blocking)

To solve this problem, instead of expecting the `.getSync` function to immediately return a response, you give it a callback.

```swift
/// async + non-blocking
HTTPClient.getAsync("http://google.com", onCompletion: { res, error in

})
```

Now, after the `.getAsync` function is done sending the request to `google.com`, it can simply continue executing your 
program. When Google's servers return a response, the CPU will be notified, and it will give the response to your callback.

## Advanced

Let's now take a deeper look at why Vapor prefers async (non-blocking) APIs over sync (blocking) ones.

### Threads

You may be thinking, what's the problem with `.getSync`? Why not just call that function on a background thread.
That is indeed a valid solution, and it would work. This style of threading is widely used and taught. However, the problem is
that threads are not "free" to create. When you're programming for iOS, this doesn't (usually) matter. You can
often spin up as many threads as you like. You have a whole CPU to yourself! Things are different on the server though. 
Web applications must respond to thousands (even millions) of requests _at the same time_. Imagine running a million instances
of your iOS app on one device. Even relatively small costs, like creating a thread, become extremely important as a web server.

### Multi-Reactor

To achieve optimal performance, Vapor only creates one thread per CPU core on your machine. This means there will be no
wasted time allocating new threads and very little wasted time switching between them. 

Each one of these threads is called an event loop, similar to Node.js. The difference is that Vapor has multiple event loops
(one for each core) where as Node.js just has one. This means you don't need to spin up multiple instances of your app
per computer for it to run optimally.

```swift
/// every incoming request has a reference
/// to its assigned event loop
router.get(...) { req in
	print(req.eventLoop) // EventLoop?
}
```

It's important that you don't make blocking calls on an event loop. If you do, all other requests running on that event loop will
be blocked. For example, if your computer has 2 cores, and you call `sleep(10)` on one of the event loops, your application will
stop responding to half of the incoming requests for 10 seconds.

### Coroutines

Coming soon.
