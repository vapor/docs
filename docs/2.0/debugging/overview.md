# Debugging

Conforming your error types to `Debuggable` allows Vapor to create richer error messages and makes debugging easier.

```swift
import Debugging

extension FooError: Debuggable {
	// conform here
}
```

Now when a `FooError` is thrown, you will get a nice message in your console.

```sh
Foo Error: You do not have a `foo`.

Identifier: DebuggingTests.FooError.noFoo

Here are some possible causes: 
- You did not set the flongwaffle.
- The session ended before a `Foo` could be made.
- The universe conspires against us all.
- Computers are hard.

These suggestions could address the issue: 
- You really want to use a `Bar` here.
- Take up the guitar and move to the beach.

Vapor's documentation talks about this: 
- http://documentation.com/Foo
- http://documentation.com/foo/noFoo
```
