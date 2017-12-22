# What is Vapor?

Vapor 3 is an [asynchronous](../async/getting-started.md), codable and protocol oriented framework. This document will outline the major lines how vapor is designed and why.

## Async

Vapor 3 async is a framework consisting of two basic principles. Futures and Streams. Both have their ideal use cases and strengths.

### Performance

Vapor's high performance is achieved by a combination of an [asynchronous architecture](../supplementary/architecture.md), Copy on Write mechanics and highly optimized lazy parsers. These three techniques combined with Swift's compiler ensure that our performance is comparable to Go.

### Type safety

Vapor is designed around type-safety and compile-time checks, ensuring that code doesn't behave in unexpected ways and shows you most problems at compile time. Vapor achieves this by leveraging Swift and its Codable protocol.

We believe type-safety is critical to both security and developer productivity.

### Easy to use

Creating a new Vapor project takes only a few minutes.

We've got you covered with our thorough documentation and have [a helpful community](vapor.team) to back it up!
