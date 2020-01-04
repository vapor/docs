# Jobs

Jobs ([vapor/jobs](https://github.com/vapor/jobs)) is a pure Swift queuing system that allows you to offload task responsibility to a side worker. 

Some of the tasks this package works well for:

- Sending emails outside of the main request thread
- Performing complex or long-running database operations 
- Ensuring job integrity and resilience 
- Speeding up response time by delaying non-critical processing
- Scheduling jobs to occur at a specific time

This package is similar to [Ruby Sidekiq](https://github.com/mperham/sidekiq). It provides the following features:

- Safe handling of `SIGTERM` and `SIGINT` signals sent by hosting providers to indicate a shutdown, restart, or new deploy.
- Different queue priorities. Allows specifying a job be run on the `email` queue, for example, versus the `data-processing` queue.
- Implements the reliable queue process to help with unexpected failures.
- Includes a maxRetryCount feature that will repeat the job until it succeeds up until a specified count.
- Uses NIO to utilize all available cores and EventLoops for jobs.
- Allows users to schedule repeating tasks

Jobs currently has one officially supported drivers which interface with the main protocol:

- [JobsRedisDriver](https://github.com/vapor/jobs-redis-driver)

Jobs also has community-based drivers:
- [JobsPostgresqlDriver](https://github.com/vapor-community/jobs-postgresql-driver)

!!! tip
    You should not install the `jobs/vapor` package directly unless you are building a new driver. Install one of the driver packages instead. 

## Getting Started

Let's take a look at how you can get started using Jobs.

### Package

The first step to using Jobs is adding one of the drivers as a dependency to your project in your SPM package manifest file. In this example, we'll use the Redis driver. 

```swift
// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "MyApp",
    dependencies: [
        /// Any other dependencies ...
        .package(url: "https://github.com/vapor-community/jobs-redis-driver.git", from: "1.0.0"),
    ],
    targets: [
        .target(name: "App", dependencies: ["JobsRedisDriver", ...]),
        .target(name: "Run", dependencies: ["App"]),
        .testTarget(name: "AppTests", dependencies: ["App"]),
    ]
)
```

Don't forget to add the module as a dependency in the `targets` array. Once you have added the dependency, regenerate your Xcode project with the following command:

```sh
open Package.swift
```

### Config

The next step is to configure the Jobs in [`configure.swift`](../getting-started/structure.md#configureswift). We'll use the Redis library as an example:

```swift
try app.jobs.use(.redis(url: "redis://\(hostname):6379"))
```

### Registering a `Job`

After modeling a job you must add it to your configuration section like this:

```swift
//Register jobs
let emailJob = EmailJob()
app.jobs.add(emailJob)
```

### Running Workers as Processes

To start a new queue worker, run `vapor run jobs`. You can also specify a specific type of worker to run: `vapor run jobs --queue emails`.

!!! tip
    Workers should stay running in production. Consult your hosting provider to find out how to keep long-running processes alive. Heroku, for example, allows you to specify "worker" dynos like this in your Procfile: `worker: Run run jobs`

### Running Workers in-process

To run a worker in the same process as your application (as opposed to starting a whole separate server to handle it), call the `JobsCommand` like this in your `boot.swift` file:

```swift
try JobsCommand(application: app, scheduled: false).startJobs(on: .default)
```

To run scheduled jobs in process, pass the `scheduled` flag:

```swift
try JobsCommand(application: app, scheduled: true).startScheduledJobs()
```