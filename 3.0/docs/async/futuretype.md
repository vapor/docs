# FutureType

FutureType is a protocol defining any entity that provides the ability to register callback closures for an object that _may_ be returned in the future.

FutureTypes call the registered closure with either an error or the `Expectation`. FutureTypes _may_ return this in the future. The can, instead, also call the closure immediately.

This pattern is adopted by [`Response`](../http/response.md) among other types. We recommend libraries to be generic to FutureType rather than depending on a specific implementation such as [`Future`](futures.md)
