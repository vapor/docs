# The `Job` Protocol

Jobs are defined by the `Job` and protocol.

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
    
    func dequeue(_ context: JobContext, _ payload: Email) -> EventLoopFuture<Void> {
        print(payload.message)
        print(payload.to)
        return context.eventLoop.future()
    }
    
    func error(_ context: JobContext, _ error: Error, _ payload: Email) -> EventLoopFuture<Void> {
        //If you don't want to handle errors you can simply return a future. You can also omit this function entirely. 
        return context.eventLoop.future()
    }
}
```

!!! tip
    Don't forget to follow the instructions in [Getting Started](/jobs/getting-started.md#registering-a-job) to add this job to your configuration file. 