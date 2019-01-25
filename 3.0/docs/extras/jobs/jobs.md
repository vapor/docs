# The `Job` Protocol

Jobs are defined by the `Job` protocol which leverages Codable to easily add type safety to your tasks. 

### Modeling a `Job`
```swift
import Foundation
import Jobs
import Vapor

struct EmailJob: Job {
    let to: String
    let from: String
    let message: String
    
    func dequeue(context: JobContext, worker: EventLoopGroup) -> EventLoopFuture<Void> {
        print("To: \(to), from: \(from), message: \(message)")
        return worker.future()
    }
    
    func error(context: JobContext, error: Error, worker: EventLoopGroup) -> EventLoopFuture<Void> {
        //If you don't want to handle errors you can simply return a future. You can also omit this function entirely. 
        return worker.future()
    }
}
```

!!! tip
    Don't forget to follow the instructions in [Getting Started](/extras/jobs/getting-started.md#registering-a-job) to add this job to your configuration file. 

There are a few important things to note about the `Job` protocol. First, any properties you add will get automatically encoded in the persistence layer and are available for use inside of the function. Second, `dequeue` and `error` are not throwing methods - in order to return an error from the function you must use `worker.future(error: myErrorHere)`. Finally, all `Job` functions return `EventLoopFuture`s meaning that you can perform non-blocking work inside of a job. 

### Using `JobContext`
In order to obtain access to services from inside of a job, you must use `JobContext`. Get started by setting up the services you want to use in `configure.swift`:

```swift
extension JobContext {
    var emailService: EmailService? {
        get {
            return userInfo["emailservice"] as? EmailService
        }
        set {
            userInfo["emailservice"] = newValue
        }
    }
}
```

Then, register this service in your `configure.swift`:

```swift
let emailService = EmailService()
services.register { _ -> EmailService in
    return emailService
}

var jobContext = JobContext()
jobContext.emailService = emailService

services.register { _ -> JobContext in
    return jobContext
}
```

Finally, you can use this service inside of a `Job` function:

```swift
import Foundation
import Jobs
import Vapor

struct EmailJob: Job {
    let to: String
    let from: String
    let message: String
    
    func dequeue(context: JobContext, worker: EventLoopGroup) -> EventLoopFuture<Void> {
        guard let emailService = context.emailService else { return worker.future(error: myError) }
        return emailService.send(to: to, from: from, message: message)
    }
    
    func error(context: JobContext, error: Error, worker: EventLoopGroup) -> EventLoopFuture<Void> {
        return worker.future()
    }
}
```