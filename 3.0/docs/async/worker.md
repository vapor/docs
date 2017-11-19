# Worker

Workers are any type that keep track of the current [EventLoop](../concepts/async.md#multi-reactor).

Worker is a simple protocol and can be conformed to if the context can return (by means of a computed property) or contain an EventLoop.

There are three primary Workers that you can use to access the eventloop and it's queue or context.

- [Request](../http/request.md) can be used, usually from within a [Route](../routing/basics.md)
- [EventLoop](../concepts/eventloop.md#multi-reactor) is itself a worker to ensure the extensions and consumers of Worker can be used, too.
- `DispatchQueue` is a worker that will return a *new and clean* EventLoop based on the current DispatchQueue
