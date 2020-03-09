# Scheduling Jobs

The Jobs package also allows you to schedule jobs to occur at certain points in time.

## Starting the scheduler worker
The scheduler requires a separate worker process to be running, similar to the queue worker. You can start the worker by running this command: 

```sh
swift run Run queues --scheduled
```

!!! tip
    Workers should stay running in production. Consult your hosting provider to find out how to keep long-running processes alive. Heroku, for example, allows you to specify "worker" dynos like this in your Procfile: `worker: Run run queues --scheduled`

## Creating a `ScheduledJob`
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

## Available builder methods
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

## Available helpers 
Jobs ships with some helpers enums to make scheduling a bit easier: 

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