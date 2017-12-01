# EventLoop

EventLoops are used to carry a thread-context with objects. In Vapor 3, requests *must* stay within the same thread [as is described here](../concepts/async.md).

Most of the time, you'll want to pass the current [Request](../http/request.md) as the eventloop.

## Types of eventloop

The following types can be used as an EventLoop:

- [Request](../http/request.md)
- DispatchQueue
