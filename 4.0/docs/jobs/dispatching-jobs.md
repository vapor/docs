# Dispatching Jobs

To dispatch a job, you need access to an instance of `Application` or `Request`. You will most likely be dispatching jobs inside of a route handler:

```swift
app.get("email") { req in
    return req
        .jobs
        .dispatch(
            EmailJob.self, 
            .init(to: "email@email.com", message: "message")
        ).map { "done" }
}
```

### Setting `maxRetryCount`

Jobs will automatically retry themselves upon error if you specify a `maxRetryCount`. For example: 

```swift
app.get("email") { req in
    return req
        .jobs
        .dispatch(
            EmailJob.self, 
            .init(to: "email@email.com", message: "message"),
            maxRetryCount: 3
        ).map { "done" }
}
```

### Specifying a delay

Jobs can also be set to only run after a certain `Date` has passed. To specify a delay, pass a `Date` into the `delayUntil` parameter in `dispatch`:

```swift
app.get("email") { req in
    return req
        .jobs
        .dispatch(
            EmailJob.self, 
            .init(to: "email@email.com", message: "message"),
            maxRetryCount: 3,
            delayUntil: someFutureDate
        ).map { "done" }
}
```

If a job is dequeued before its delay parameter, the job will be re-queued by the driver. 

### Specify a priority 

Jobs can be sorted into different queue types/priorities depending on your needs. For example, you may want to open an `email` queue and a `background-processing` queue to sort jobs. 

Start by extending `JobsQueueName`:

```swift
extension JobsQueueName {
    static let emails = JobsQueueName(string: "emails")
}
```

Then, specify the queue type when you retrieve the `jobs` object:

```swift
app.get("email") { req in
    return req
        .jobs(.emails)
        .dispatch(
            EmailJob.self, 
            .init(to: "email@email.com", message: "message"),
            maxRetryCount: 3,
            delayUntil: someFutureDate
        ).map { "done" }
}
```

If you do not specify a queue the job will be run on the `default` queue. Make sure to follow the instructions in [Getting Started](/jobs/getting-started.md#running-workers) to start workers for each queue type. 