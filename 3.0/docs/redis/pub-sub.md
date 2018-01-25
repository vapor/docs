# Publish & Subscribe

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

To subscribe for notifications you need to open a new connection to the Redis server that listens for messages.

A single client can listen to one or more channels, which is provided using a set of unique channel names. The result of subscribing is a `RedisChannelStream`.

```swift
let client = RedisClient.subscribe(to: ["some-notification-channel", "other-notification-channel"]) // Future<RedisChannelStream>
```

This stream will receive messages asynchronously.This works like [any other async stream](../async/streams.md)

Notifications consist of the channel and payload.

```swift
client.do { channelStream in
    channelStream.drain { notification in
      print(notification.channel)

      let payload = notification.payload

      // TODO: Process the payload
    }
}.catch { error in
    // handle error
}
```
