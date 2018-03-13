# Pipelining

Pipelining is used for sending multiple commands at once. The performance advantages become apparent when sending a large number of queries. Redis' pipelining cuts down latency by reducing the RTT (Round Trip Time) between the client and server. Pipelining also reduces the amount of IO operations Redis has to perform, this increases the amount of queries per second Redis can handle. 

### Use cases
Sometimes multiple commands need to be executed at once.  Instead of sending those commands individually in a loop, pipelining allows the commands to be batched and sent in one request. A common scenario might be needing to set a key and increment a count, pipelining those commands would be ideal.

### Enqueuing Commands

```swift
 let pipeline = connection.makePipeline()
 let result = try pipeline
         .enqueue(command: "SET", arguments: ["KEY", "VALUE"])
         .enqueue(command: "INCR", arguments: ["COUNT"])
         .execute() // Future<[RedisData]>
         
```
Note: Commands will not be executed until execute is called.
