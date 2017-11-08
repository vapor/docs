### This document

This document covers both `Codable` and `Async`, the two primary concepts in Vapor 3. Understanding these 2 concepts is essential, even for existing Vapor 1 and 2 users.

# Codable

Codable is any type that's both `Encodable` and `Decodable`. Encodable types can be serialized to a format, and Decodable types can be deserialized from a format.

If you only want your type to be serializable to another type, then you conform to `Encodable`. This will allow serializing this type to other formats such as JSON, XML, MySQL rows, MongoDB/BSON and more. But not backwards.

If you want to be able to construct your type from the raw data, you can conform your type to `Decodable`. This will allow converting serialized data to your model (the reverse of `Encodable`), allowing JSON, XML, MySQL and MongoDB data to construct your model. This will not allow serialization.

If you want both serialization and deserialization, you can conform to `Codable`.

For the best experience you should conform one of the above protocols in the *definition* of your `struct` or `class`. This way the compiler can infer the protocol requirements automatically. Conforming to these protocols in an extension will require you to manually implement the protocol requirements.

```swift
struct User: Codable {
  var username: String
  var age: Int
}
```

With this addition, the above struct can now be (de-)serialized between JSON, XML, MongoDB BSON, MySQL and more!

# Async

To understand asynchronous code you must first understand what synchronous code does.

Synchronous code is code that writes top to bottom and executes exactly in that order independent of your use case. It does not use callbacks, it does not use futures and it does not use streams. Many information is not immediately available. The internet has a delay between any communication traffic. Querying a database requires sending the query to the database, waiting for the database to process and execute the request, and then receiving the requested information. To keep code synchronous you need to "block" the thread. This results in rendering the thread unusable until the response has been received. This is, naturally, inefficient. You're wasting a thread and much performance.

The only clean solution here is to do nonblocking operations. This means that once you send the query, you continue to the next line of code immediately without waiting/blocking. The problem that arises is that the next lines of code are dependent on the result of the previous query's results. For this reason, Vapor 3 introduces [Futures](../async/promise-future-introduction.md). Futures are very common in many (high performance) ecosystems.
