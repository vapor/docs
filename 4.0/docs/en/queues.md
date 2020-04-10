# Queues

Vapor Queues ([vapor/queues](https://github.com/vapor/queues)) is a pure Swift queuing system that allows you to offload task responsibility to a side worker. 

Some of the tasks this package works well for:

- Sending emails outside of the main request thread
- Performing complex or long-running database operations 
- Ensuring job integrity and resilience 
- Speeding up response time by delaying non-critical processing
- Scheduling jobs to occur at a specific time

This package is similar to [Ruby Sidekiq](https://github.com/mperham/sidekiq). It provides the following features:

- Safe handling of `SIGTERM` and `SIGINT` signals sent by hosting providers to indicate a shutdown, restart, or new deploy.
- Different queue priorities. For example, you can specify a queue job to be run on the email queue and another job to be run on the data-processing queue.
- Implements the reliable queue process to help with unexpected failures.
- Includes a `maxRetryCount` feature that will repeat the job until it succeeds up until a specified count.
- Uses NIO to utilize all available cores and EventLoops for jobs.
- Allows users to schedule repeating tasks

Queues currently has one officially supported driver which interfaces with the main protocol:

- [QueuesRedisDriver](https://github.com/vapor/queues-redis-driver)

Queues also has community-based drivers:
- [JobsPostgresqlDriver](https://github.com/vapor-community/jobs-postgresql-driver)

!!! tip
    You should not install the `vapor/queues` package directly unless you are building a new driver. Install one of the driver packages instead. 

## Getting Started

Let's take a look at how you can get started using Queues.

### Package

The first step to using Queues is adding one of the drivers as a dependency to your project in your SwiftPM package manifest file. In this example, we'll use the Redis driver. 

```swift
// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "MyApp",
    dependencies: [
        /// Any other dependencies ...
        .package(url: "https://github.com/vapor/queues-redis-driver.git", from: "1.0.0"),
    ],
    targets: [
        .target(name: "App", dependencies: [
            .product(name: "QueuesRedisDriver", package: "queues-redis-driver")
        ]),
        .target(name: "Run", dependencies: [.target(name: "App")]),
        .testTarget(name: "AppTests", dependencies: [.target(name: "App")]),
    ]
)
```

If you edit the manifest directly inside Xcode, it will automatically pick up the changes and fetch the new dependency when the file is saved. Otherwise, from Terminal, run `swift package resolve` to fetch the new dependency.

### Config

The next step is to configure Queues in `configure.swift`. We'll use the Redis library as an example:

```swift
try app.queues.use(.redis(url: "redis://127.0.0.1:6379"))
```

### Registering a `Job`

After modeling a job you must add it to your configuration section like this:

```swift
//Register jobs
let emailJob = EmailJob()
app.queues.add(emailJob)
```

### Running Workers as Processes

To start a new queue worker, run `vapor run queues`. You can also specify a specific type of worker to run: `vapor run queues --queue emails`.

!!! tip
    Workers should stay running in production. Consult your hosting provider to find out how to keep long-running processes alive. Heroku, for example, allows you to specify "worker" dynos like this in your Procfile: `worker: Run run queues`

### Running Workers in-process

To run a worker in the same process as your application (as opposed to starting a whole separate server to handle it), call the convenience methods on `Application`:

```swift
try app.queues.startInProcessJobs(on: .default)
```

To run scheduled jobs in process, call the following method:

```swift
try app.queues.startScheduledJobs()
```

!!! warning
    If you don't start the queue worker either via command line or the in-process worker the jobs will not dispatch. 

## The `Job` Protocol

Jobs are defined by the `Job` protocol.

### Modeling a `Job` object:
```swift
import Vapor 
import Foundation 
import Queues 

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
    Don't forget to follow the instructions in **Getting Started** to add this job to your configuration file. 

## Dispatching Jobs

To dispatch a queue job, you need access to an instance of `Application` or `Request`. You will most likely be dispatching jobs inside of a route handler:

```swift
app.get("email") { req -> EventLoopFuture<String> in
    return req
        .queue
        .dispatch(
            EmailJob.self, 
            .init(to: "email@email.com", message: "message")
        ).map { "done" }
}
```

### Setting `maxRetryCount`

Jobs will automatically retry themselves upon error if you specify a `maxRetryCount`. For example: 

```swift
app.get("email") { req -> EventLoopFuture<String> in
    return req
        .queue
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
app.get("email") { req -> EventLoopFuture<String> in
    let futureDate = Date(timeIntervalSinceNow: 60 * 60 * 24) // One day
    return req
        .queue
        .dispatch(
            EmailJob.self, 
            .init(to: "email@email.com", message: "message"),
            maxRetryCount: 3,
            delayUntil: futureDate
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
app.get("email") { req -> EventLoopFuture<String> in
    let futureDate = Date(timeIntervalSinceNow: 60 * 60 * 24) // One day
    return req
        .queues(.emails)
        .dispatch(
            EmailJob.self, 
            .init(to: "email@email.com", message: "message"),
            maxRetryCount: 3,
            delayUntil: futureDate
        ).map { "done" }
}
```

If you do not specify a queue the job will be run on the `default` queue. Make sure to follow the instructions in **Getting Started** to start workers for each queue type. 

## Scheduling Jobs

The Queues package also allows you to schedule jobs to occur at certain points in time.

### Starting the scheduler worker
The scheduler requires a separate worker process to be running, similar to the queue worker. You can start the worker by running this command: 

```sh
swift run Run queues --scheduled
```

!!! tip
    Workers should stay running in production. Consult your hosting provider to find out how to keep long-running processes alive. Heroku, for example, allows you to specify "worker" dynos like this in your Procfile: `worker: Run run queues --scheduled`

### Creating a `ScheduledJob`
To being, start by creating a new `ScheduledJob`:

```swift
import Vapor
import Jobs

struct CleanupJob: ScheduledJob {
    // Add extra services here via dependency injection, if you need them.

    func run(context: QueueContext) -> EventLoopFuture<Void> {
        // Do some work here, perhaps queue up another job.
        return context.eventLoop.makeSucceededFuture(())
    }
}
```

Then, in your configure code, register the scheduled job: 

```swift
app.queues.schedule(CleanupJob())
    .yearly()
    .in(.may)
    .on(23)
    .at(.noon)
```

The job in the example above will be run every year on May 23rd at 12:00 PM.

!!! tip
    The Scheduler takes the timezone of your server.

### Available builder methods
There are five main methods that can be called on a scheduler, each of which creates its respective builder object that contains more helper methods. You should continue building out a scheduler object until the compiler does not give you a warning about an unused result. See below for all available methods:

| Helper Function | Available Modifiers                   | Description                                                                    |
|-----------------|---------------------------------------|--------------------------------------------------------------------------------|
| `yearly()`      | `in(_ month: Month) -> Monthly`       | The month to run the job in. Returns a `Monthly` object for further building.  |
| `monthly()`     | `on(_ day: Day) -> Daily`             | The day to run the job in. Returns a `Daily` object for further building.      |
| `weekly()`      | `on(_ weekday: Weekday) -> Daily` | The day of the week to run the job on. Returns a `Daily` object.               |
| `daily()`       | `at(_ time: Time)`                    | The time to run the job on. Final method in the chain.                         |
|                 | `at(_ hour: Hour24, _ minute: Minute)`| The hour and minute to run the job on. Final method in the chain.              |
|                 | `at(_ hour: Hour12, _ minute: Minute, _ period: HourPeriod)` | The hour, minute, and period to run the job on. Final method of the chain |
| `hourly()`      | `at(_ minute: Minute)`                 | The minute to run the job at. Final method of the chain.                      |

### Available helpers 
Queues ships with some helpers enums to make scheduling easier: 

| Helper Function | Available Helper Enum                 |
|-----------------|---------------------------------------|
| `yearly()`      | `.january`, `.february`, `.march`, ...|
| `monthly()`     | `.first`, `.last`, `.exact(1)`        |
| `weekly()`      | `.sunday`, `.monday`, `.tuesday`, ... |
| `daily()`       | `.midnight`, `.noon`                  |

To use the helper enum, call in to the appropriate modifier on the helper function and pass the value. For example:

```swift
// Every year in January 
.yearly().in(.january)

// Every month on the first day 
.monthly().on(.first)

// Every week on Sunday 
.weekly().on(.sunday)

// Every day at midnight
.daily().at(.midnight)
```
