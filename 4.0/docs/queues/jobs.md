# The `Job` Protocol

Jobs are defined by the `Job` protocol.

### Modeling a `Job` object:
```swift
import Vapor 
import Foundation 
import Jobs 

struct Email: Codable {
    let to: String
    let message: String
}

struct EmailJob: Job {
    typealias Payload = Email
    
    func dequeue(_ context: QueueContext, _ payload: Email) -> EventLoopFuture<Void> {
        // This is where you would send the email
        return context.eventLoop.future()
    }
    
    func error(_ context: QueueContext, _ error: Error, _ payload: Email) -> EventLoopFuture<Void> {
        // If you don't want to handle errors you can simply return a future. You can also omit this function entirely. 
        return context.eventLoop.future()
    }
}
```

!!! tip
    Don't forget to follow the instructions in [Getting Started](/queues/getting-started.md#registering-a-job) to add this job to your configuration file. 
