# API Design

For contributing code we have guidelines that we strive for, and requirements.
Accepted code *must* comply to all requirements and *should* follow all guidelines.

## Requirements

The requirements stated here *must* be followed for all Vapor 3 code starting with the beta.
We designed all of Vapor 3's APIs (including the Async library) to require little to no breaking changes over the coming years.

### Enums

`enum` is to be used almost never. *Only* use enums if there realistically will not be any other cases that are added in the future.

### Classes

Always mark classes as `final`. If you plan on using a `public` or `open` class, look into a protocol or generics oriented approach.

### Low-level APIs

Low level APIs such as sockets, SSL, cryptography and HTTP should be oriented towards simplicity, maintainability and correctness.
If you feel an API becomes more complex for end-users, you can add high level APIs that rely on the low-level ones.

### Tests

The unit tests must have a minimum of 80% code coverage.

### Uniformity

Stick to the familiar API patterns. If connecting a socket has the following signature:

```swift
try socket.connect(to: "example.com", port: 80)
```

Copy the signature, rather than adding an extra case.
If you need more metadata for connecting, consider setting them in the initializer or as a variable on the type.

### Binary data

Binary data should be passed around in 3 formats;

- ByteBuffer
- Data
- [UInt8]

You should use `ByteBuffer` when working with Streams to limit copies and improve the stream chaining applicability.
`Data` for larger sets of data (>1000 bytes) and `[UInt8]` for smaller data sets (<=1000 bytes).

### Dictionaries and Arrays

Where you'd normally use a dictionary (such as HTTP headers) you _should_ create a separate struct instead.
This improves the freedom for future optimizations and keeps the implementation separate from the end user API.
This results in better future-proofing and helps building better (more specialized) APIs.

## Guidelines

### Performance

Performance regression is acceptable to some degree but should be limited.
Here are some tips on achieving high performance code or ensuring more performance can be added in the future.

### Access modifiers

Try to use the `public` keyword as little as possible. More APIs adds more complexity than freedom.
Specialized use cases are always free to build their own modules, and a `public` keyword can be added but not undone.

### Comments

Green is the future, and we believe in that, too! I'm not talking about green energy, but the often green coloured code comments.
Code comments important for the users of an API. Do not add meaningless comments, though.

### Documentation

Every `public` function, type and variable _should_ have a link to the documentation describing it's use case(s) with examples.

### Argument labels

Along with uniformity described above, you should try to keep argument labels short and descriptive.

### Argument count

We strive for functions with a maximum of 3 parameters, although certain use cases permit for more arguments.
Often called functions should strive for less arguments.

### Initializer complexity

Initializers are complex enough, it is recommended to _not_ put optional arguments in an initializer since they can be modified on the entity itself.
Try to limit the initializer to what really matters, and put the rest in `func`tions.
