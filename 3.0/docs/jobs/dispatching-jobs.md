# Dispatching Jobs

To dispatch a job, you need access to an instance of `QueueService`. For example:

```swift
final class EmailController: RouteCollection {
    let queue: QueueService
    
    init(queue: QueueService) {
        self.queue = queue
    }
    
    func boot(router: Router) throws {
        router.get("/sendemail", use: sendEmail)
    }
    
    func sendEmail(req: Request) throws -> Future<HTTPStatus> {
        let job = EmailJob(to: "to@to.com", from: "from@from.com", message: "message")
        return queue.dispatch(job: job).transform(to: .ok)
    }
}
```

!!! tip
    `QueueService` is thread safe so you can pass it directly to a controller.

### Setting `maxRetryCount`

Jobs will automatically retry themselves upon error if you specify a `maxRetryCount`. For example: 

```swift
queue.dispatch(job: job, maxRetryCount: 10)
```

### Specify a priority 

Jobs can be sorted into different queue types/priorities depending on your needs. For example, you may want to open an `email` queue and a `background-processing` queue to sort jobs. 

Start by extending `QueueType`:

```swift
extension QueueType {
    static let emails = QueueType(name: "emails")
}
```

Then, specify the queue type when you call `dispatch`:

```swift
queue.dispatch(job: job, queue: .emails)
```

If you do not specify a queue the job will be run on the `default` queue. Make sure to follow the instructions in [Getting Started](/jobs/getting-started.md#running-workers) to start workers for each queue type. 