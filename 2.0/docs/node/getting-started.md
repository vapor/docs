# Getting Started

## Why do we have Node?

The web is very stringy, Swift is very type-safe, this is a major problem when doing web development in Swift. Node is our attempt at providing a solution to this problem.

## What is Node?

Node is a data abstraction with an emphasis on being an intermediary between distinct types. For example, json from a client might use node to convert between the JSON and itself.

## How do I use it?

Node can be a little different to work with at first if you're familiar with less type-safe languages, let's look at a couple of examples and how we might start using Node in our projects. Most often, we'll be working with Node conversions.

## NodeInitializable

NodeInitializable can be read and understood as `An object that can be initialized with a Node`. Let's look at a simple implementation.

```Swift
struct Person: NodeInitializable {
    let name: String
    let age: Int

    init(node: Node) throws {
        name = try node.get("name")
        age = try node.get("age")
    }
}
```

Now that we have this, we can easily convert abstract data to a Person. Here's how that might look:

```swift
let person = try Person(node: json)
```

> Note: There are some more advanced functionality options for JSON and database Row types in particular, we'll cover that later.

By conforming our `Person` object to `NodeInitializable`, we can also use more advanced cases such as arrays:

```swift
let people = try [Person](node: jsonArray)
```

## NodeRepresentable

NodeRepresentable can be read and understood as `An object that can be represented as a Node`. Let's take a look at a simple implementation. We'll stick with the `Person` example above

```swift
extension Person: NodeRepresentable {
    func makeNode(in context: Context) throws -> Node {
        var node = Node(context)
        try node.set("name", name)
        try node.set("age", age)
        return node
    }
}
```

Now that we've done this, we can easily convert our `person` or a collection of `Person` objects into a `Node`.

```swift
let node = try person.makeNode(in: nil)
```

And also for collections, like arrays

```swift
let node = try [kim, joe, jan].makeNode(in: nil)
```

## Context

Up to this point, we've seen `Context` a lot, but what's it for. When we're serializing or mapping an object, we might have a lot of different situations we're mapping differently for. Maybe one is for the database, one is for the view, one is for JSON, etc.

If you're using Vapor, we provide a lot of contexts and more native integration options, but here's how one might define their own.

```swift
import Node

final class MyContext: Context {
}

let myContext = MyContext()

extension Context {
    var isMyContext: Bool {
        return self is MyContext
    }
}
```

Now inside our object, we could add special behavior.

```swift
extension Person: NodeRepresentable {
    func makeNode(in context: Context) throws -> Node {
        var node = Node(context)
        try node.set("name", name)
        try node.set("age", age)
        if context.isMyContext {
            try node.set("special-attribute", special)
        }
        return node
    }
}
```

We might call it like this:

```swift
let specialNode = person.makeNode(in: myContext)
```

This is a common usage, but can be adapted for any scenario where we require special metadata to help us properly serialize or map our object.

## `NodeConvertible`

NodeConvertible is simply the combination of Representable and Initializable. These objects can be converted easily to and from node. Taking our Person object from earlier, we should be able to do this:

```swift
// ..
let node = person.makeNode(in: myContext)
let back = try Person(node: node)
print("\(person) went to node and back to \(back)")
```
