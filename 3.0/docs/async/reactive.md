# Reactive programming

As part of the Vapor 3 ecosystem we embrace reactiveness.

This allows us to process a lot of data with a low response time efficiently and balanced,
making Vapor 3 handle a lot of clients simultaniously and remain performant.

As part of our API design we strive to minimize the impact on code.

### Reducing code impact

Most of our code impact is reduced using protocols.
By conforming Futures and Streams to the `Codable` protocol we can use reactiveness throughout all components of Vapor 3.

This allows for reactive templating with less code than before reactiveness was introduced.

## Rules

The following rules are critical to reactive programming with Vapor 3:

### Information flow

Stream data must be asynchronously available. This means that when input is received, the information stays intact until new data is requested or the sending stream is cancelled/closed.

Output to another stream must stay intact (in the case of `ByteBuffer`, must not be deallocated or reused) until a new request for data has been made.

### Upstream

Requesting data from upstream must only be done if you do not have enough information to complete a request from downstream.

### Downstream

You *must not* feed more data to downstream than was requested.

<!-- TODO: @Tanner? Any more rules? -->
