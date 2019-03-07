# The `Job` Protocol

Jobs are defined by the `Job` and `JobData` protocols.

### Modeling a `JobData` object
```swift
import Foundation
import Jobs
import Vapor

struct EmailJobContext: JobData {
    let to: String
    let from: String
    let message: String
}
```

### Modeling a `Job` object:
```swift
import Foundation
import Jobs 
import Vapor 

struct EmailJob: Job {
    let emailService: EmailService
    
    func dequeue(_ context: JobContext, _ data: EmailJobContext) -> EventLoopFuture<Void> {
        return emailService.sendEmail(to: data.to, subject: data.subject, content: data.message)
    }
    
    func error(_ context: JobContext, _ error: Error, _ data: EmailJobContext) -> EventLoopFuture<Void> {
        //If you don't want to handle errors you can simply return a future. You can also omit this function entirely. 
        return worker.future()
    }
}
```

!!! tip
    Don't forget to follow the instructions in [Getting Started](/extras/jobs/getting-started.md#registering-a-job) to add this job to your configuration file. 

!!! warning
    Each job's `Context` needs to have a unique name. Do not nest your context objects without uniquely naming them. 

`dequeue` and `error` are not throwing methods - in order to return an error from the function you must use `worker.future(error: myErrorHere)`.