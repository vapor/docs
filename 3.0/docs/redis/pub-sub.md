# Publish & Subscribe

Redis' Publish and Subscribe model is really useful for notifications.

### Use cases

Pub/sub is used for notifying subscribers of an event.
A simple and common event for example would be a chat message.

A channel consists of a name and group of listeners. Think of it as being `[String: [Listener]]`.
When you send a notification to a channel you need to provide a payload.
Each listener will get a notification consisting of this payload.

Channels must be a string. For chat groups, for example, you could use the database identifier.

### Publishing

You cannot get a list of listeners, but sending a payload will emit the amount of listeners that received the notification.
Sending (publishing) an event is done like so:

```swift
// Any redis data
let notification: RedisData = "My-Notification"

client.publish(notification, to: "my-channel")
```

If you want access to the listener count:

```swift
let notifiedCount = client.publish(notification, to: "my-channel") // Future<Int>
```

### Subscribing

To subscribe for notifications you're rendering an entire Redis Client useless in exchange for listening to events.

A single client can listen to one or more channels, which is provided using a set of unique channel names. The result of subscribing is a `SubscriptionStream`.

```swift
let notifications = client.subscribe(to: ["some-notification-channel", "other-notification-channel"])
```

If you try to use the client after subscribing, all operations will fail. These errors are usually emitted through the Future.

This stream will receive messages asynchronously from the point of `draining`. This works like any other async stream.

Notifications consist of the channel and payload.

```swift
notifications.drain { notification in
  print(notification.channel)

  let payload = notification.payload

  // TODO: Process the payload
}
```
